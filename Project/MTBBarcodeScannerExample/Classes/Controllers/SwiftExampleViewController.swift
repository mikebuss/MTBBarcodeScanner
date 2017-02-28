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
        
        scanner = MTBBarcodeScanner(previewView: previewView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try self.scanner?.startScanning(resultBlock: { codes in
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.scanner?.stopScanning()
        
        super.viewWillDisappear(animated)
    }
}
