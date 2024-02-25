//
//  PhotoDepth.swift
//  PointCloudDepthDemo
//
//  Created by tuyw.tu on 2024/2/21.
//

import UIKit
import ARKit
import AVFoundation
import MetalKit


class PhotoDepthViewController: UIViewController {
    
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var depthImageView: UIImageView!
    private var videoCapture: VideoCapture!
    private var depthImage: CIImage?
    private var currentDrawableSize: CGSize!
    var currentCameraType: CameraType = .back(true)
    private let serialQueue = DispatchQueue(label: "com.photo.depth.queue")


    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupSession()
        
//        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
//        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.frame = view.bounds
////        view.layer.addSublayer(previewLayer)
//        view.layer.insertSublayer(previewLayer, at: 0)
        
        depthImageView = UIImageView()
        depthImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        depthImageView.center = view.center
        depthImageView.contentMode = .scaleAspectFill
        view.addSubview(depthImageView)
        
        
        self.currentDrawableSize = view.frame.size
        videoCapture = VideoCapture(cameraType: currentCameraType,
                                    preferredSpec: nil,
                                    previewContainer: view.layer)
        
        videoCapture.syncedDataBufferHandler = { [weak self] videoPixelBuffer, depthData, face in
            guard let self = self else { return }
            
//            self.videoImage = CIImage(cvPixelBuffer: videoPixelBuffer)

            var useDisparity: Bool = false
            var applyHistoEq: Bool = false
//            DispatchQueue.main.sync(execute: {
//                useDisparity = self.disparitySwitch.isOn
//                applyHistoEq = self.equalizeSwitch.isOn
//            })
            
            
            self.serialQueue.async {
        
                guard let depthData = useDisparity ? depthData?.convertToDisparity() : depthData else { return }
                
                guard let ciImage = depthData.depthDataMap.transformedImage(targetSize: self.currentDrawableSize, rotationAngle: 0) else { return }
                self.depthImage = applyHistoEq ? ciImage.applyingFilter("YUCIHistogramEqualization") : ciImage
                
                
                let ciContext = CIContext()
                let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
                DispatchQueue.main.async {
                    self.depthImageView.image = UIImage(cgImage: cgImage!)
                }
            }
        }
        videoCapture.setDepthFilterEnabled(true)
    
    }
    
    func setupSession() {
        self.captureSession = AVCaptureSession()
        
        // Select a depth-capable capture device.
        // builtInDualWideCamera、builtInDualCamera
        guard let videoDevice = AVCaptureDevice.default(.builtInDualCamera,
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
        // Shoot the photo, using a custom class to handle capture delegate callbacks.
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if !self.captureSession.isRunning {
//            DispatchQueue.global().async {
//                self.captureSession.startRunning()
//            }
//        }
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.imageBufferHandler = nil
        videoCapture.stopCapture()
        
        super.viewWillDisappear(animated)
//        if captureSession.isRunning {
//            DispatchQueue.global().async {
//                self.captureSession.stopRunning()
//            }
//        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }
}

extension PhotoDepthViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let depthMap = photo.depthData?.depthDataMap else {
            return
        }
        
        let ciImage = CIImage(depthData: photo.depthData!)
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciImage!, from: ciImage!.extent)
        
        let image = UIImage(cgImage: cgImage!, scale: 1, orientation: .right)
//        let image = UIImage(cgImage: cgImage!)
        depthImageView.image = image
        
        print(depthMap)
    }
}
