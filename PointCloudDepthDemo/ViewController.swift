//
//  ViewController.swift
//  PointCloudDepthDemo
//
//  Created by tuyw on 2024/2/20.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    var sceneView: ARSCNView!
    var pointCloudView: PointCloud!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.session.delegate = self
        sceneView.debugOptions = .showWorldOrigin
        view.addSubview(sceneView)
        
        pointCloudView = PointCloud()
        sceneView.scene.rootNode.addChildNode(pointCloudView)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
//        if ARConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
//        }
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }


}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depthMap = frame.sceneDepth?.depthMap else { return }
        let capturedImage = frame.capturedImage
        
        let w = CVPixelBufferGetWidth(depthMap)
        let h = CVPixelBufferGetHeight(depthMap)
        let cameraIntrinsics = frame.camera.intrinsics
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float>.size
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float>.self)
        
        var pointCloud = [simd_float3]()
        
        for y in 0..<h {
            for x in 0..<w {
                let pixel = floatBuffer[y * bytesPerRow + x]
                if pixel != 0 {
                    let depth = Float(pixel)
                    let xrw = (Float(x) - cameraIntrinsics[2][0]) * depth / cameraIntrinsics[0][0]
                    let yrw = (Float(y) - cameraIntrinsics[2][1]) * depth / cameraIntrinsics[1][1]

                    let point = simd_float3(x: xrw, y: yrw, z: depth)
                    
                    pointCloud.append(point)
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        
        let point = simd_float3(x: 0.1, y: 0.1, z: 0.1)
        pointCloudView.updatePoints([point])
        
    }
    
}
