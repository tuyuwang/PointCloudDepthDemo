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
    private var interaction: ImageAnalysisInteraction?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!

    
    var images: [UIImage] = []
    
    override func viewDidLoad() {
        interaction = ImageAnalysisInteraction()
        interaction?.preferredInteractionTypes = .imageSubject
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "Cell")
        
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
        images.removeAll()

        Task {
            await startAnalyzer(image: sceneView.snapshot())
            
//            let subject = await interaction?.subject(at: sender.location(in: imageView))
//            let subjects = await interaction?.subjects
            
            await interaction?.subjects.forEach({ subject in
                Task {
                    let image = try? await subject.image
                    images.append(image!)
                    collectionView.reloadData()
                }
            })
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

extension PickupObjectsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.row]
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    
}

class ImageCell: UICollectionViewCell {
    var imageView: UIImageView
    override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        super.init(frame: frame)
    
        imageView.frame = contentView.bounds
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
