# MTBBarcodeScanner CHANGELOG

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
