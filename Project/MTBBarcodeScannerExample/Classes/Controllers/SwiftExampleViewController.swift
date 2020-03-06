//
//  MTBSwiftExampleViewController.swift
//  MTBBarcodeScannerExample
//
//  Created by Mike Buss on 11/9/16.
//
//

import UIKit
import MTBBarcodeScanner

class SwiftExampleViewController: UIViewController {
    
    @IBOutlet var previewView: UIView!
    var scanner: MTBBarcodeScanner?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scan all types of codes
        scanner = MTBBarcodeScanner(previewView: previewView)
        
        // If you want to scan only QR codes, use this instead!
//        scanner = MTBBarcodeScanner(metadataObjectTypes: [AVMetadataObject.ObjectType.qr.rawValue], previewView: previewView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MTBBarcodeScanner.requestCameraPermission(success: { success in
            if success {
                do {
                    // Start scanning with the front camera
                    try self.scanner?.startScanning(with: .front,
                                                    resultBlock: { codes in
                                                        if let codes = codes {
                                                            for code in codes {
                                                                let stringValue = code.stringValue!
                                                                print("Found code: \(stringValue)")
                                                            }
                                                        }
                    })
                } catch {
                    NSLog("Unable to start scanning")
                }
            } else {
                let alertController = UIAlertController(title: "Scanning Unavailable", message: "This app does not have permission to access the camera", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.scanner?.stopScanning()
        
        super.viewWillDisappear(animated)
    }
    
    @IBAction func switchCameraTapped(sender: UIButton) {
        self.scanner?.flipCamera()
    }
}
