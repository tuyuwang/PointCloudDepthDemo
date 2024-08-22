//
//  PickupObjectsFromImage.swift
//  PointCloudDepthDemo
//
//  Created by tuyw.tu on 2024/8/21.
//

import Foundation
import Vision
import VisionKit
import ARKit

class PickupObjectsViewController: UIViewController {
    @IBOutlet weak var resultImageView: UIImageView!
    private var interaction: ImageAnalysisInteraction?
    
    @IBOutlet weak var sceneView: ARSCNView!
    override func viewDidLoad() {
         interaction = ImageAnalysisInteraction()
        interaction?.preferredInteractionTypes = .imageSubject
        
//        interaction.delegate = self
//        imageView.addInteraction(interaction!)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        Task {
            await startAnalyzer(image: sceneView.snapshot())
            
//            let subject = await interaction?.subject(at: sender.location(in: imageView))
            let subjects = await interaction?.subjects
            
            
            resultImageView.image = try? await interaction?.image(for: subjects!)
            print("analysis completion")
        }
    }
    
    
    func startAnalyzer(image: UIImage) async {
        let configuration = ImageAnalyzer.Configuration([])
        let analyzer = ImageAnalyzer()
        let analysis = try? await analyzer.analyze(image, configuration: configuration)
        interaction?.analysis = analysis
    }
}



//extension PickupObjectsViewController: ImageAnalysisInteractionDelegate {
//    
//}

extension PickupObjectsViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
}
