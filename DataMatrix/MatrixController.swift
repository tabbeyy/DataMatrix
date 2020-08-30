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

    // Handles video in/out
    var session: AVCaptureSession?
    
    // Handles data matrix detection
    var metadataOutput: AVCaptureMetadataOutput?
    
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
        self.session = AVCaptureSession()
        self.metadataOutput = AVCaptureMetadataOutput()
        
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
        
        if (self.session!.canAddOutput(self.metadataOutput!)) {
            self.session!.addOutput(self.metadataOutput!)
            self.metadataOutput!.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // List the types of data matrix we are looking for
            self.metadataOutput!.metadataObjectTypes = [.aztec, .qr]
        }
        
    }
    
    /// Displays a failure screen to the user
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
        UIView.animate(withDuration: 0.9, animations: {
            self.view.backgroundColor = .systemRed
        })
        
        // Then add label to the screen
        UIView.animate(withDuration: 0.5, delay: 0.4, animations: {
            self.view.addSubview(label)
        })
    }
    
    /*  For now lets just use an alert
    @objc func pressedButton(sender: UIButton!, view: UIView) {
        // Close the pop up view
        self.view.popupView.removeFromSuperview()
    }
    
    /// Displays a popup containing the scanned QR code
    func matrixFoundPopup(data: String) {
        let width = self.view.frame.width
        let height = self.view.frame.height
        
        let popupView: UIView = UIView(frame: CGRect(x: width/2, y: height/2, width: 200, height: 100))
        popupView.center = CGPoint(x: width/2, y:height/2)
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = popupView.frame.height * (10 / 57)
        
        let scannedText: UILabel = UILabel()
        scannedText.backgroundColor = .clear
        scannedText.text = data
        scannedText.textAlignment = .center
        scannedText.textColor = .black
        
        
        let closeButton: UIButton = UIButton()
        closeButton.backgroundColor = .systemTeal
        closeButton.addTarget(self, action: #selector(self.pressedButton(sender:)), for: .touchUpInside)
        
        popupView.addSubview(scannedText)
        popupView.addSubview(closeButton)
        
        self.view.addSubview(popupView)
        
    }
    */
    
    func displayData(data: String) {
        let alert = UIAlertController(title: "Found a data matrix", message: data, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
}

extension MatrixController: AVCaptureMetadataOutputObjectsDelegate {

    /// Called when a data matrix is scanned
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Try and get the decoded value
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject
                else {return}
            guard let stringValue = readableObject.stringValue
                else {return}
            
            // Display the result
            displayData(data: stringValue)
        }
    }
}
