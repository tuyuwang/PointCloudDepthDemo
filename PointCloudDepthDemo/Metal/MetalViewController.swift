//
//  MetalViewController.swift
//  PointCloudDepthDemo
//
//  Created by tuyw.tu on 2024/5/11.
//

import UIKit
import SwiftUI

final class MetalViewController: UIViewController {
    
    var arProvider: ARProvider = ARProvider()
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        let metalViewController = UIHostingController(rootView: MetalPointCloud(arData: arProvider))
        self.addChild(metalViewController)
        view.addSubview(metalViewController.view)
        
        metalViewController.view.translatesAutoresizingMaskIntoConstraints = false
        metalViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        metalViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        metalViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        metalViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        // 将UIHostingController添加到当前的UIViewController
        metalViewController.didMove(toParent: self)
    }
}
