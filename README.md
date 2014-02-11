# MTBBarcodeScanner

A lightweight, easy-to-use barcode scanning library for iOS 7. 

To scan barcodes, simply supply the library with a `UIView` to display the camera feed and wait for input using the result block. The block will be called for every frame a barcode is read.

See demo project for examples of capturing one code, multiple codes, or highlighting codes as valid or invalid in the live preview.

## Installation

MTBBarcodeScanner can be installed via [CocoaPods](http://cocoapods.org) by adding the following line to your Podfile:

`pod "MTBBarcodeScanner"`

## Example Usage

#### Initialization

To initialize an instance of `MTBBarcodeScanner`:

```objc
self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:self.previewView];
```

Where `previewView` is the `UIView` in which the camera input will be displayed.

If you only want to scan for certain MetaObjectTypes, you can initialize with the `initWithMetadataObjectTypes:previewView:` method:

```objc
self.scanner = [[MTBBarcodeScanner alloc] initWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]
                                                              previewView:self.previewView];
```

#### Scanning

To read the first code and stop scanning:

```objc
[self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        AVMetadataMachineReadableCodeObject *code = [codes firstObject];
        NSLog(@"Found code: %@", code.stringValue);
        [self.scanner stopScanning];
    }];
```

If the camera is pointed at more than one 2-dimensional code, you can read all of them:

```objc
[self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        for (AVMetadataMachineReadableCodeObject *code in codes) {
            NSLog(@"Found code: %@", code.stringValue);
        }
        [self.scanner stopScanning];
    }];
```

**Note:** This doesn't work for 1-dimensional barcodes. See [relevant Apple document](https://developer.apple.com/library/ios/technotes/tn2325/_index.html).

To continuously read and only output unique codes: 

```objc
[self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        for (AVMetadataMachineReadableCodeObject *code in codes) {
            if ([self.uniqueCodes indexOfObject:code.stringValue] == NSNotFound) {
                [self.uniqueCodes addObject:code.stringValue];
                gs
                NSLog(@"Found unique code: %@", code.stringValue);
            }
        }
    }];
```

## Sample Barcodes

<img src="https://raw2.github.com/mikebuss/MTBBarcodeScanner/master/valid.png" width=150 height=150>

<img src="https://raw2.github.com/mikebuss/MTBBarcodeScanner/master/invalid.png" width=150 height=150>

## Developer

Mike Buss
- [Website](http://mikebuss.com)
- [GitHub](https://github.com/mikebuss)
- [Twitter](https://twitter.com/michaeltbuss)
- [Email](mailto:mike@mikebuss.com)

## License

MTBBarcodeScanner is available under the MIT license. See the LICENSE file for more info.
