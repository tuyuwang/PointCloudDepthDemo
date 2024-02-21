//
//  PhotoDepth.swift
//  PointCloudDepthDemo
//
//  Created by tuyw.tu on 2024/2/21.
//

import UIKit
import ARKit
import AVFoundation

class PhotoDepthViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSession()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
//        view.layer.addSublayer(previewLayer)
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func setupSession() {
        self.captureSession = AVCaptureSession()
        
        // Select a depth-capable capture device.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
            for: .video, position: .unspecified)
            else { fatalError("No dual camera.") }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            self.captureSession.canAddInput(videoDeviceInput)
            else { fatalError("Can't add video input.") }
        self.captureSession.beginConfiguration()
        self.captureSession.addInput(videoDeviceInput)


        // Set up photo output for depth data capture.
        photoOutput = AVCapturePhotoOutput()
        guard self.captureSession.canAddOutput(photoOutput)
            else { fatalError("Can't add photo output.") }
        self.captureSession.addOutput(photoOutput)
        self.captureSession.sessionPreset = .photo
        // Enable delivery of depth data after adding the output to the capture session.
        photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
        self.captureSession.commitConfiguration()
        
        
    }
    @IBAction func takePhoto(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
        photoSettings.isDepthDataDeliveryEnabled = true
        // Shoot the photo, using a custom class to handle capture delegate callbacks.
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.startRunning()
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            DispatchQueue.global().async {
                self.captureSession.stopRunning()
            }
        }
    }
}

extension PhotoDepthViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let depthMap = photo.depthData?.depthDataMap else {
            return
        }
        
        print(depthMap)
    }
}
