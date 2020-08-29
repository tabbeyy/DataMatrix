//
//  MatrixController.swift
//  DataMatrix
//
//  Created by Tom Abbott on 29/08/2020.
//  Copyright © 2020 Tom Abbott. All rights reserved.
//

import UIKit
import AVFoundation


class MatrixController: UIViewController {

    var session: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if we can use the camera
        if (requestMediaPermissions()) {
            self.setupCaptureSession()
        } else {
            self.permissionsFailed()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (self.session?.isRunning == false) {
            self.session?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (self.session?.isRunning == true) {
            self.session?.stopRunning()
        }
    }
    
    /// Request camera permissions
    func requestMediaPermissions() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // We have access
                return true
            
            case .notDetermined:
                // We need to request permission
                var result: Bool = false
                
                AVCaptureDevice.requestAccess(for: .video) {granted in
                    if granted {
                        result = true
                    } 
                }
                
                return result
            
            case .denied:
                // We have been denied access
                return false
            
            case .restricted:
                // The user cannot grant access
                return false
            
            @unknown default:
                // Handle cases that could be added in the future
                return false
        }
    }
    
    func setupCaptureSession() {
        // AVCaptureSession controls sensor input and output
        self.session = AVCaptureSession()
        
        // Try and get camera access
        guard let cam = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: cam)
        else {
            // Fail to get access
            fatalError("Cannot access camera device")
        }
        
        self.session?.addInput(input)
        
        // Add video preview of camera to screen
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session!)
        previewLayer.frame = self.view.bounds
        self.view.layer.addSublayer(previewLayer)
        
        self.session?.startRunning()
    }
    
    func permissionsFailed() {
        let width = self.view.frame.width
        let height = self.view.frame.height
        
        let label = UILabel(frame: CGRect(x: width/2, y: height/2, width: width-20, height: 100))
        label.center = CGPoint(x: width/2, y: height/2)
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.text = "Couldn't access the camera"
        
        // Animate background colour to red
        UIView.animate(withDuration: 1, animations: {
            self.view.backgroundColor = .systemRed
        })
        
        // Then add label to the screen
        UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
            self.view.addSubview(label)
        })
    }
}
