//
//  PickupObjectsFromDiskImage.swift
//  PointCloudDepthDemo
//
//  Created by tuyw.tu on 2025/2/26.
//

import Foundation
import Vision
import VisionKit

class PickupObjectsImageViewController: UIViewController {
    private var interaction: ImageAnalysisInteraction?
    var imageURLs: [URL] = []

    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadImages()
    }

    func loadImages() {
        if let urls = loadImagePaths() {
            imageURLs = urls
            collectionView.reloadData()
        }
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize  = CGSize(width: self.view.bounds.size.width/3.1, height: 200)
        layout.minimumInteritemSpacing  = 0.1
        layout.minimumLineSpacing  = 5

        collectionView = UICollectionView(frame: view.bounds,  collectionViewLayout: layout)
        collectionView.register(ImageCell.self,  forCellWithReuseIdentifier: "ImageCell")
        collectionView.dataSource  = self
        collectionView.delegate  = self
        view.addSubview(collectionView)
        collectionView.frame = CGRect(x: 0, y: 64, width: self.view.bounds.width, height: self.view.bounds.height - 64)
    }
    
    func loadImagePaths() -> [URL]? {
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for:  .cachesDirectory, in: .userDomainMask).first!
        let testimgsURL = documentsURL.appendingPathComponent("testimgs")
        do {
            let contents = try fileManager.contentsOfDirectory(at:  testimgsURL,
                                                               includingPropertiesForKeys: nil,
                                                               options: .skipsHiddenFiles)
            return contents.filter  { $0.pathExtension.lowercased()  == "jpg" || $0.pathExtension  == "png" || $0.pathExtension  == "jpeg" }
        } catch {
            print("Error loading images: \(error)")
            return nil
        }
    }
    
}

extension PickupObjectsImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  "ImageCell", for: indexPath) as! ImageCell
        let imageURL = imageURLs[indexPath.item]
        cell.imageView.image  = UIImage(contentsOfFile: imageURL.path)
        cell.layer.masksToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ImageCell
        let preVC = PickupObjectsVisionViewController()
        preVC.targetImage = cell.imageView.image
        self.navigationController?.pushViewController(preVC, animated: true)
    }
}


class PickupObjectsVisionViewController: UIViewController {
    var targetImage: UIImage?
    private var interaction: ImageAnalysisInteraction?
    private var imagePreview: UIImageView?

    override func viewDidLoad() {
        interaction = ImageAnalysisInteraction()
        interaction?.preferredInteractionTypes = .imageSubject
        
        imagePreview = UIImageView()
        imagePreview?.contentMode = .scaleAspectFit
        imagePreview?.frame = self.view.bounds
        view.addSubview(imagePreview!)
        
        guard let targetImage = targetImage else { return }
        
        Task {
            await startAnalyzer(image: targetImage)
            
//            let subject = await interaction?.subject(at: sender.location(in: imageView))
//            let subjects = await interaction?.subjects
            
            await interaction?.subjects.forEach({ subject in
                Task {
                    let image = try? await subject.image
                    imagePreview?.image = image
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
