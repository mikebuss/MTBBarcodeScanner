//
//  MTBBarcodeScanner.h
//  MTBBarcodeScannerExample
//
//  Created by Mike Buss on 2/8/14.
//
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MTBBarcodeScanner : NSObject

/**
 *  Initialize a scanner that will feed the camera input
 *  into the given UIView.
 *
 *  @param previewView View that will be overlayed with the live feed from the camera input.
 *
 *  @return An instance of MTBBarcodeScanner
 */
- (instancetype)initWithPreviewView:(UIView *)previewView;

/**
 *  Initialize a scanner that will feed the camera input
 *  into the given UIView. Only codes with a type given in
 *  the metaDataObjectTypes array will be reported to the result
 *  block when scanning is started using startScanningWithResultBlock:
 *
 *  @see startScanningWithResultBlock:
 *
 *  @param metaDataObjectTypes Array of AVMetadataObjectTypes to scan for. Only codes with types given in this array will be reported to the resultBlock.
 *  @param previewView View that will be overlayed with the live feed from the camera input.
 *
 *  @return An instance of MTBBarcodeScanner
 */
- (instancetype)initWithMetadataObjectTypes:(NSArray *)metaDataObjectTypes
                                previewView:(UIView *)previewView;

/**
 *  Returns whether the camera exists in this device.
 *
 *  @return YES if the device has a camera.
 */
+ (BOOL)cameraIsPresent;

/**
 *  Returns whether scanning is prohibited by the user of the device.
 *
 *  @return YES if the user has prohibited access to (or is prohibited from accessing) the camera.
 */
+ (BOOL)scanningIsProhibited;

/**
 *  Request permission to access the camera on the device.
 *
 *  The success block will return YES if the user granted permission, has granted permission in the past, or if the device is running iOS 7.
 *  The success block will return NO if the user denied permission, is restricted from the camera, or if there is no camera present.
 */
+ (void)requestCameraPermissionWithSuccess:(void (^)(BOOL success))successBlock;

/**
 *  Start scanning for barcodes. The camera input will be added as a sublayer
 *  to the UIView given for previewView during initialization.
 *
 *  @param resultBlock Callback block for captured codes. If the scanner was instantiated with initWithMetadataObjectTypes:previewView, only codes with a type given in metaDataObjectTypes will be reported.
 */
- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock;

/**
 *  Stop scanning for barcodes. The live feed from the camera will be removed as a sublayer from the previewView given during initialization.
 */
- (void)stopScanning;

/**
 *  Whether the scanner is currently scanning for barcodes
 *
 *  @return YES if the scanner is currently scanning for barcodes
 */
- (BOOL)isScanning;

@end
