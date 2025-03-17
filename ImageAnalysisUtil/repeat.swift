//
//  main.swift
//  ImageAnalysisUtil
//
//  Created by tuyw.tu on 2025/3/14.
//

import Foundation
import SwiftUI
import ArgumentParser
import Vision
import VisionKit

@main
struct ImageAnalysisUtil: ParsableCommand {
    @Argument(help: "Input directory path")
    var inputDir: String
    
    @Argument(help: "Output directory path")
    var outputDir: String
    
    @MainActor
    func run() throws {
        let fileManager = FileManager.default
        let supportedExtensions = ["jpg", "jpeg", "png"]

        let overlayView = ImageAnalysisOverlayView()
        overlayView.preferredInteractionTypes = [.imageSubject]

        // 获取目录内容
        guard let contents = try? fileManager.contentsOfDirectory(atPath:  inputDir) else {
            throw RuntimeError("无法读取输入目录")
        }
        
        // 过滤图片文件
        let imageFiles = contents.filter  { file in
            let ext = URL(fileURLWithPath: file).pathExtension.lowercased()
            return supportedExtensions.contains(ext)
        }
        
        let group = DispatchGroup()
        // 遍历处理图片
        for file in imageFiles {
            let fullPath = URL(fileURLWithPath: inputDir).appendingPathComponent(file).path
            // 转换为 Image 对象
            if let nsImage = NSImage(contentsOfFile: fullPath) {
                print("成功加载图像: \(file)")
                
                group.enter()
                
                // 创建父Task并等待完成
                Task {
                    print("开始分析图像")

                    // 第一阶段：图像分析
                    await startAnalyzer(image: nsImage, overlayView: overlayView)
                    
                    print("等待分析图像")

                    // 第二阶段：并发获取所有subject图像
                    let subject = await overlayView.subjects.first
                    
                    group.leave()
                    
                }
                
                // 此处会立即执行（如需等待需在外层再加await）
                print("1111")
            
            } else {
                print("警告: 无法加载 \(file)")
            }
        }
        
        group.wait()
    }
    
    func startAnalyzer(image: NSImage, overlayView: ImageAnalysisOverlayView) async {
        let configuration = ImageAnalyzer.Configuration([])
        let analyzer = ImageAnalyzer()
        let analysis = try? await analyzer.analyze(image,  orientation: .down, configuration: configuration)
        await MainActor.run {
            overlayView.analysis = analysis
        }
    }
}
 
struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description  = description }
}

