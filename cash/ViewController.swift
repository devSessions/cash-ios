//
//  ViewController.swift
//  cash
//
//  Created by Rabin Gaire on 10/6/18.
//  Copyright © 2018 Rabin Gaire. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var infoLabel: UILabel!
    
    var tap: UITapGestureRecognizer!
    var takePhoto = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.text = "Tap the Screen to identify the cash"
        
        // getting video from back camera
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        // preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.bringSubviewToFront(infoLabel)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if(takePhoto) {
            takePhoto = false
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            guard let model = try? VNCoreMLModel(for: Cash().model) else { return }
            let request = VNCoreMLRequest(model: model) {
                (finishedReq, error) in
                
                guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
                
                guard let firstObservation = results.first else { return }
                
                DispatchQueue.main.async {
                    let resultString = "Detected \(firstObservation.identifier.firstUppercased) Rupees"
                    self.infoLabel.text = resultString
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: resultString)
                }
            }
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        takePhoto = true;
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension StringProtocol {
    var firstUppercased: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }
    var firstCapitalized: String {
        guard let first = first else { return "" }
        return String(first).capitalized + dropFirst()
    }
}
