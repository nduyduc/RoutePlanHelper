//
//  PictureViewController.swift
//  RoutePlanHelper
//
//  Created by Duy Nguyen on 13/6/19.
//  Copyright © 2019 Duy Nguyen. All rights reserved.
//

import UIKit
import CoreMotion

class PictureViewController: UIViewController {

    @IBOutlet weak var pictureView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    let motionManager: CMMotionManager = CMMotionManager()
    
    var lastRotation = 0.0
    
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: handleMotion(data:error:))
        imageView.image = image
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(recognizer:)))
        view.addGestureRecognizer(pinch)
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handlePinch(recognizer: UIPinchGestureRecognizer) {
        imageView.transform = imageView.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
        recognizer.scale = 1
    }
    
    /**
     The motion handler
     */
    func handleMotion(data: CMDeviceMotion?, error: Error?) -> Void {
        guard let data = data else {
            print("Motion failure: \(String(describing: error))")
            return
        }
        
        let rotation = atan2(data.gravity.x, data.gravity.y) - Double.pi
        let rotationDiff = rotation - lastRotation
        imageView.transform = imageView.transform.rotated(by: CGFloat(rotationDiff))
        lastRotation = rotation
    }
    
}
