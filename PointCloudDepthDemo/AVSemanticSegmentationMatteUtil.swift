//
//  AVSemanticSegmentationMatteUtil.swift
//  PointCloudDepthDemo
//
//  Created by tuyw.tu on 2025/4/7.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage.CIFilterBuiltins

class SegmentationMatteViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "girl")
        self.imageView.image = image
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let image = self.imageView.image else { return }

        let base = CIImage(image: image)
        
        let maxcomp = CIFilter.maximumComponent()
        maxcomp.inputImage = base
        
        var makeup = maxcomp.outputImage
        let gamma = CIFilter.gammaAdjust()
        gamma.inputImage = makeup
        gamma.power = 0.5
        makeup = gamma.outputImage
        
        var matte = CIImage(image: image, options: [.auxiliarySemanticSegmentationSkinMatte: true])
        let scale = CGAffineTransformMakeScale(
            base!.extent.size.width/matte!.extent.size.width, base!.extent.size.height/matte!.extent.size.height)
        matte = matte?.transformed(by: scale)
        
        
        let blend = CIFilter.blendWithMask()
        blend.backgroundImage = base
//        blend.backgroundImage = CIImage(image: UIImage(named: "bg")!)
        blend.inputImage = makeup
        blend.maskImage = matte
        
        guard let result = blend.outputImage else { return }
    
        self.imageView.image = UIImage(ciImage: result)
    }
}
