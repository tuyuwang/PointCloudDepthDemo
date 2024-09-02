//
//  ViewController.swift
//  PointCloudDepthDemo
//
//  Created by tuyw on 2024/2/20.
//

import UIKit
import ARKit

typealias Float3 = SIMD3<Float>

extension Float {
    static let degreesToRadian = Float.pi / 180
}

class ViewController: UIViewController {
    
    var sceneView: ARSCNView!
    var redCloudView: PointCloud!
    var yellowCloudView: PointCloud!
    var greenCloudView: PointCloud!
    var capturePoints: [simd_float3]?
    
    private let orientation = UIInterfaceOrientation.landscapeRight
    private lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)

    static func cameraToDisplayRotation(orientation: UIInterfaceOrientation) -> Int {
        switch orientation {
        case .landscapeLeft:
            return 180
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return -90
        default:
            return 0
        }
    }
    
    static func makeRotateToARCameraMatrix(orientation: UIInterfaceOrientation) -> matrix_float4x4 {
        // flip to ARKit Camera's coordinate
        let flipYZ = matrix_float4x4(
            [1, 0, 0, 0],
            [0, -1, 0, 0],
            [0, 0, -1, 0],
            [0, 0, 0, 1] )

        let rotationAngle = Float(cameraToDisplayRotation(orientation: orientation)) * .degreesToRadian
        return flipYZ * matrix_float4x4(simd_quaternion(rotationAngle, Float3(0, 0, 1)))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.session.delegate = self
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = .showWorldOrigin
        view.insertSubview(sceneView, at: 0)
        
        redCloudView = PointCloud()
        redCloudView.color = .red
        sceneView.scene.rootNode.addChildNode(redCloudView)
        
        yellowCloudView = PointCloud()
        yellowCloudView.color = .yellow
        sceneView.scene.rootNode.addChildNode(yellowCloudView)
        
        greenCloudView = PointCloud()
        greenCloudView.color = .green
        sceneView.scene.rootNode.addChildNode(greenCloudView)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
//        if ARConfiguration.supportsFrameSemantics(.sceneDepth) {
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
//        }
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }

    @IBAction func captureClick(_ sender: Any) {
        guard let points = capturePoints else {
            return
        }
        
        let stringData = points.map { "(\($0.x), \($0.y), \($0.z))" }.joined(separator: ", ")
    
        DispatchQueue.global().async {

            let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in:.userDomainMask).first!
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            let timestamp = formatter.string(from: date)
            let name = "pointCloud_\(timestamp).txt"
            var filePath = documentsDirectory.appendingPathComponent(name)

            do {
                try stringData.write(to: filePath, atomically: true, encoding: .utf8)
                print("数据成功写入到沙盒中的文件")
            } catch {
                print("写入数据时发生错误: \(error)")
            }
        }
                   
    }
    
    
    
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depthMap = frame.smoothedSceneDepth?.depthMap else { return }
        guard let confidenceMap = frame.smoothedSceneDepth?.confidenceMap else { return }

        let depth_w = CVPixelBufferGetWidth(depthMap)
        let depth_h = CVPixelBufferGetHeight(depthMap)
        
        let viewMatrix = frame.camera.viewMatrix(for: orientation)
        let viewMatrixInversed = viewMatrix.inverse
        let localToWorld = viewMatrixInversed * rotateToARCamera
        
        var cameraIntrinsics = frame.camera.intrinsics
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float>.size
        let scaleRes = simd_float2(x: Float(frame.camera.imageResolution.width) / Float(depth_w),
                                   y: Float(frame.camera.imageResolution.height) / Float(depth_h))

    
        cameraIntrinsics[0][0] /= scaleRes.x
        cameraIntrinsics[1][1] /= scaleRes.y

        cameraIntrinsics[2][0] /= scaleRes.x
        cameraIntrinsics[2][1] /= scaleRes.y
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferLockBaseAddress(confidenceMap, CVPixelBufferLockFlags(rawValue: 0))

        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float>.self)
        let confidenceFloatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(confidenceMap), to: UnsafeMutablePointer<UInt8>.self)

        redCloudView.points.removeAll()
        yellowCloudView.points.removeAll()
        greenCloudView.points.removeAll()
        
        autoreleasepool {
            var pointCloud = [simd_float3]()
            
            for y in 0..<depth_h {
                for x in 0..<depth_w {
        
                    let pixel = floatBuffer[y * bytesPerRow + x]
                    let confidence = confidenceFloatBuffer[y * bytesPerRow + x] // 0、1、2 ARConfidenceLevel

                    if pixel > 0 {
                        let depth = Float(pixel)
                        
                        let xw = (Float(x) - cameraIntrinsics[2][0]) * depth / cameraIntrinsics[0][0]
                        let yw = (Float(y) - cameraIntrinsics[2][1]) * depth / cameraIntrinsics[1][1]
                        let point = simd_float4(x: xw, y: yw, z: depth, w: 1)
                        let pointWorld = localToWorld * point
                        let point3D = simd_float3(x: pointWorld.x, y: pointWorld.y, z: pointWorld.z)
                        pointCloud.append(point3D)
                        
                        switch confidence {
                        case 0:
                            redCloudView.points.append(point3D)
                            break
                        case 1:
                            yellowCloudView.points.append(point3D)
                            break
                        case 2:
                            greenCloudView.points.append(point3D)
                            break
                        default:
                            break
                        }
                    }
                }
            }
            
            redCloudView.update()
            yellowCloudView.update()
            greenCloudView.update()
            
            capturePoints = pointCloud
        }
        
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        
    }

}
