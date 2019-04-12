# MTBBarcodeScanner CHANGELOG

## [Unreleased]

There are no unreleased changes.

## 5.0.11

- Fix rare crash when stopping the barcode scanner

Special thanks to [@anuraagshakya](https://github.com/anuraagshakya) for the work on this release!

## 5.0.10

- Guard all uses of iOS 10+ classes and APIs with appropriate @available() tests

Special thanks to [@bayoung](https://github.com/bayoung) for the work on this release!

## 5.0.9

- Made call to freezeCapture non-blocking.

Special thanks to [@shagedorn](https://github.com/shagedorn) for the work on this release!

## 5.0.8

- Fixed warnings being generated with latest Xcode version.

Special thanks to [@anuraagshakya](https://github.com/anuraagshakya) for the work on this release!

## 5.0.7

- Added the ability to scan from a particular camera on startup with startScanningWithCamera:resultBlock:error.

## 5.0.6

- Fixed build warnings in Xcode 9.4. 

Special thanks to [@badchoice](https://github.com/badchoice) for all of the work on this release!

## 5.0.5

- Updated app for deprecation warnings in iOS 11

## 5.0.4

- Improvements to performance of still capture

## 5.0.3

- Fixed blocking issue with scanRect call

## 5.0.2

- Handle deprecation of devicesWithMediaType in iOS 10
- Fixed an issue where stopScanning() could potentially hang
- Updated sample project for iOS 10 deprecation warnings

Thanks to @alistra and @shagedorn with their help in this release!

## 5.0.1

- Fixed issue with orientation changes not registering under some circumstances.

Special thanks to [@juliangoacher](https://github.com/juliangoacher) for all of the work on this release!

## 5.0.0

- Setting the `scanRect` must now be set in the `didStartScanning` block.
- Removed MTBTorchModeAuto
- Added error handling when setting torch mode.

Special thanks to [@shagedorn](https://github.com/shagedorn) for all of the work on this release!

## 4.0.0

- Setting the `camera` property directly is now deprecated in favor of the more-helpful `setCamera:error:` method.
- Methods that accept an error argument now have a return value to satisfy Xcode analyzer.

Special thanks to [@shagedorn](https://github.com/shagedorn) for all of the work on this release!

## 3.1.0

- Fixed issue where calling a method on UIImagePickerController could prompt a rejection from the App Store if a `NSPhotoLibraryUsageDescription` is not provided in the Info.plist file. Details are [here](https://github.com/mikebuss/MTBBarcodeScanner/issues/86). Thanks @brblakley!
- Fixed an issue with setting the camera using the `camera` property setter

## 3.0.0

- Errors are now propagated to the `startScanning` methods. You may now supply an NSError to this method that will be updated in the event scanning could not be started.
- The scanning methods have now been changed to:

```
- (void)startScanningWithError:(NSError **)error;
- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock error:(NSError **)error;
```

## 2.1.0

- Now uses AVCaptureFocusModeContinuousAutoFocus by default, per issue [#81](https://github.com/mikebuss/MTBBarcodeScanner/issues/81). Thanks [@JacopoKenzo](https://github.com/JacopoKenzo)!

## 2.0.3

- Fixed bug where `resultBlock` could be called when nil. Thanks [@navicor90](https://github.com/navicor90)!

## 2.0.2

- Fixed bug with Carthage support and missing import

## 2.0.1

- Added a minor bug fix for CocoaPods support

## 2.0.0

- Added support for Carthage. Thanks [@hardikdevios](https://github.com/hardikdevios)!

## 1.9.1

- Removed NSLog statement Thanks [@brblakley](https://github.com/brblakley)!

## 1.9.0

- Added support for tapping the view to focus the camera

## 1.8.11

- Fixed an issue with iOS 7 support. Thanks [@kiwox](https://github.com/kiwox)!

## 1.8.10

- Fixed an issue with freezing the camera and stopping capture in the demo project. Thanks [@huuang](https://github.com/huuang)!

## 1.8.9

- Fixed issue with scanning still images on iOS 7.

## 1.8.8

- Fixed flicker issue with setting `torchMode` property. To avoid flickering when turning on the torch, set the `torchMode` property *after* you call `startScanning`.

## 1.8.7

- Setting the `scanRect` value now correctly checks the video orientation. Thanks [@peterpaulis](https://github.com/peterpaulis)!

## 1.8.6

- Added support for capturing still images with new `captureStillImage:` method. Thanks [@peterpaulis](https://github.com/peterpaulis)!

## 1.8.5

- Fixed issue where the `scanRect` property needed to be explicitly set in order to scan barcodes.

## 1.8.4

- Added the ability to limit scanning to only a section of the screen using the new `scanRect` property. See the file `MTBAdvancedExampleViewController` in the demo project for an example. Thanks [@Shannon-Yang](https://github.com/Shannon-Yang)!

## 1.8.3

- Added the `didStartScanningBlock` property, which stores a block that's called when the barcode scanner initializes. This is useful for presenting an activity spinner while the scanner loads. Thanks to [@jaybowong](https://github.com/jaybowong) for the suggestion!
- Exposed the `resultBlock` property, which will allow the results to be dynamically set before or after the scanner starts scanning.
- Added a `startScanning` method, which will start scanning using the block properties set by the user. See README for sample usage of this.

## 1.8.2

- Added the `previewLayer` property to expose the underlying preview layer. For those not using auto layout, it may be necessary to adjust this layer when the device rotates.

## 1.8.1

- The `hasTorch` method can now be called when the scanner is not scanning. (Thanks [felipowsky](https://github.com/felipowsky)!)

## 1.8.0

Features:

- Added [hasTorch](https://github.com/mikebuss/MTBBarcodeScanner/pull/40) method. (Thanks to [felipowsky](https://github.com/felipowsky) for the implementation, and [jaybowong](https://github.com/jaybowong) for the suggestion!)
- Added `freezeCapture` and `unfreezeCapture` methods. (Thanks [felipowsky](https://github.com/felipowsky)!)

## 1.7.1

Allow setting torchMode to On before scanner starts. (Thanks [felipowsky](https://github.com/felipowsky)!)

## 1.7.0

Added support for controlling the torch. (Thanks [felipowsky](https://github.com/felipowsky)!)

## 1.6.1

Bug Fixes:
- Removed duplicate method call

## 1.6.0

Bug Fixes:
- Further fixes for issue #25: focus issue

## 1.5.0

Bug Fixes:
- Fixed an issue with the auto focus range restriction and focus point incorrectly persisting. (Thanks [sebastianludwig](https://github.com/sebastianludwig)!). Read more [here](https://github.com/mikebuss/MTBBarcodeScanner/issues/25).

## 1.4.0

Enhancements:
- Scan codes from the front or back camera! Thanks to [lanbozhang](https://github.com/lanbozhang).

## 1.3.2

Enhancements:
- Use AVCaptureSessionPresetHigh for session preset for higher quality video. (Thanks [@rshevchuk](https://github.com/rshevchuk)!)

## 1.3.1

Bug Fixes:
- Removed CocoaPods build phases from test target to fix issue [#19](https://github.com/mikebuss/MTBBarcodeScanner/issues/19).

## 1.3.0

Enhancements:
- Added support for the following:
  - AVMetadataObjectTypeInterleaved2of5Code
  - AVMetadataObjectTypeITF14Code
  - AVMetadataObjectTypeDataMatrixCode

Thanks to [@hdoria](https://github.com/hdoria) for [bringing this](https://github.com/mikebuss/MTBBarcodeScanner/issues/15) to my attention!

## 1.2.0

Enhancements:
- The capture preview layer now inherits the corner radius of the previewView's layer. Thanks [@tupps](https://github.com/tupps)!

## 1.1.18

Enhancements:
- Removed `scanningIsAvailable` and `scanningIsAvailableAndAllowed` methods in favor of `requestCameraPermissionWithSuccess:`, which requests camera permission and returns the result in a block.

## 0.1.8

Enhancements:
- Added `scanningIsAvailableAndAllowed` and `scanningIsProhibited` methods. Thanks to [@MattLewin](https://github.com/MattLewin) for the fix!

## 0.1.7

Bug Fixes:
- Fixed issue with preview orientation when starting in landscape. Thanks to [@laptobbe](https://github.com/laptobbe) for the fix!

## 0.1.6

Bug Fixes:
- Updated `captureOrientationForInterfaceOrientation` to handle all cases, including the new `UIInterfaceOrientationUnknown`. Thanks to [@emilstahl](https://github.com/emilstahl) for the fix!
- Updated sample project to recommended settings for Xcode 6

## 0.1.5

Bug Fixes:
- `stopScanning` was not correctly discarding the existing session, causing a lock.
- Scanner now stops scanning on a background thread

Thanks to [@brandonschlenker](https://github.com/brandonschlenker) for the fix!

## 0.1.4

Bug Fixes:
- The logic to check for the unsupported type (`AVMetadataObjectTypeFace`) was inverted. Thanks to [@Dario848](https://github.com/Dario848) for the fix!

## 0.1.3

Bug Fixes:
- Fixed issue with setting auto range restriction and focus point of interest on older models of iPads

## 0.1.2

Version 0.1.2 adds improvements to documentation and formatting.

Demo Project Enhancements:
- Added Kiwi testing framework

## 0.1.1

Features:
- Allow calling of `stopScanning` if scanning is unavailable to the device to make everything a little cleaner

Bug Fixes:
- Fixed issue with podspec `source_files` attribute

## 0.1.0

Initial release.
