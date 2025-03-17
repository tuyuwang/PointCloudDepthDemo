//
//  ViewController.swift
//  ImageAnalysisUtil-OS
//
//  Created by tuyw.tu on 2025/3/14.
//

import Cocoa
import Vision
import VisionKit
import AppKit
 
/// 保存 NSImage 到指定路径
/// - Parameters:
///   - image: 要保存的图片对象
///   - url: 目标文件路径（需包含文件名和扩展名）
///   - format: 图片格式，默认 PNG
///   - jpegQuality: JPEG 质量（0.0-1.0），默认 0.8
/// - Returns: 保存结果（成功/失败）
@discardableResult
func saveImage(_ image: NSImage,
               to url: URL,
               format: NSBitmapImageRep.FileType = .png,
               jpegQuality: CGFloat = 0.8) -> Bool {
    
    // 创建目录结构
    let fileManager = FileManager.default
    do {
        try fileManager.createDirectory(at:  url.deletingLastPathComponent(),
                                        withIntermediateDirectories: true,
                                        attributes: nil)
    } catch {
        print("创建目录失败: \(error.localizedDescription)")
        return false
    }
    
    // 转换图片数据
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData) else {
        print("图片数据转换失败")
        return false
    }
    
    // 根据格式生成数据
    let imageData: Data?
    switch format {
    case .jpeg:
        imageData = bitmapImage.representation(using:  .jpeg,
                                               properties: [.compressionFactor: jpegQuality])
    case .png:
        imageData = bitmapImage.representation(using:  .png,
                                               properties: [:])
    default:
        print("不支持的图片格式")
        return false
    }
    
    // 写入文件
    guard let data = imageData else {
        print("生成图片数据失败")
        return false
    }
    
    do {
        try data.write(to:  url)
        return true
    } catch {
        print("保存失败: \(error.localizedDescription)")
        return false
    }
}
 
class ViewController: NSViewController {
    @IBOutlet weak var inputPathTextField: NSTextField!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var message: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressIndicator.isIndeterminate  = false
        progressIndicator.minValue  = 0
        progressIndicator.maxValue  = 100
        progressIndicator.doubleValue  = 0
    }
    
    @IBAction func startExecution(_ sender: NSButton) {
        progressIndicator.doubleValue = 0
        let inputPath = inputPathTextField.stringValue
        
        let fileManager = FileManager.default
        let supportedExtensions = ["jpg", "jpeg", "png"]
        
        // 获取目录内容
        guard let contents = try? fileManager.contentsOfDirectory(atPath:  inputPath) else {
            return
        }
        
        // 过滤图片文件
        let imageFiles = contents.filter  { file in
            let ext = URL(fileURLWithPath: file).pathExtension.lowercased()
            
            return supportedExtensions.contains(ext)
        }
        message.stringValue = "目录下图片共: \(imageFiles.count)张"
        progressIndicator.maxValue = Double(imageFiles.count)
        
        // 遍历处理图片
        var i = 0
        var s = 0
        let begin = CACurrentMediaTime()
        for file in imageFiles {
            let fullPath = URL(fileURLWithPath: inputPath).appendingPathComponent(file).path
            let outputPath = "\(inputPath)/output/\(file)"
            // 转换为 Image 对象
            if let nsImage = NSImage(contentsOfFile: fullPath) {
                print("成功加载图像: \(file)")
                                
                // 创建父Task并等待完成
                Task {
                    print("开始分析图像")
                    
                    // 第一阶段：图像分析
                    let success = await startAnalyzer(image: nsImage, outputPath: outputPath)
                    i = i  + 1
                    s = success ? s + 1 : s
                    await MainActor.run {
                        progressIndicator.doubleValue = Double(i)
                        message.stringValue = "处理图片: \(i)/\(imageFiles.count), 成功:\(s)张"
                        if i == imageFiles.count {
                            let time = CACurrentMediaTime() - begin
                            message.stringValue = message.stringValue + "\n" + "结果输出在: \(inputPath)/output"
                            message.stringValue = message.stringValue + "\n" + "".appendingFormat("总耗时: %.2fs", time)
                        }
                    }
                    
                }
                
                // 此处会立即执行（如需等待需在外层再加await）
                print("1111")
            
            } else {
                print("警告: 无法加载 \(file)")
            }
        }
        
    }
    
    func updateProgress(_ progress: Double) {
        DispatchQueue.main.async  {
            self.progressIndicator.doubleValue  = progress
        }
    }
    
    func startAnalyzer(image: NSImage, outputPath: String) async -> Bool {
        
        let overlayView = ImageAnalysisOverlayView()
        overlayView.preferredInteractionTypes = [.imageSubject]
        
        let configuration = ImageAnalyzer.Configuration([])
        let analyzer = ImageAnalyzer()
        let analysis = try? await analyzer.analyze(image,  orientation: .up, configuration: configuration)
        await MainActor.run {
            overlayView.analysis = analysis
        }
        
        // 第二阶段：并发获取所有subject图像
        if let image = try? await overlayView.subjects.first?.image {
            print("保存图片: \(outputPath)")
            saveImage(image, to: URL(fileURLWithPath: outputPath))
            return true
        }
        
        print("分析失败: \(outputPath)")
        return false
    }

}
