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

typedef NS_ENUM(NSUInteger, MTBCamera) {
    MTBCameraBack,
    MTBCameraFront
};

typedef NS_ENUM(NSUInteger, MTBTorchMode) {
    MTBTorchModeOff,
    MTBTorchModeOn,
    MTBTorchModeAuto
};

@interface MTBBarcodeScanner : NSObject

/**
 *  Set which camera to use. See MTBCamera for options.
 */
@property (nonatomic, assign) MTBCamera camera;

/**
 *  Control the torch on the device, if present.
 */
@property (nonatomic, assign) MTBTorchMode torchMode;

/**
 *  If set, only barcodes inside this area will be scanned.
 */
@property (nonatomic, assign) CGRect scanRect;

/**
 *  Layer used to present the camera input. If the previewView
 *  does not use auto layout, it may be necessary to adjust the layers frame.
 */
@property (nonatomic, strong) CALayer *previewLayer;

/*!
 @property didStartScanningBlock
 @abstract
 Optional callback block that's called when the scanner finished initializing.
 
 @discussion
 Optional callback that will be called when the scanner is initialized and the view
 is presented on the screen. This is useful for presenting an activity indicator
 while the scanner is initializing.
 */
@property (nonatomic, copy) void (^didStartScanningBlock)();

/*!
 @property resultBlock
 @abstract
 Block that's called for every barcode captured. Returns an array of AVMetadataMachineReadableCodeObjects.
 
 @discussion
 The resultBlock is called once for every frame that at least one valid barcode is found.
 The returned array consists of AVMetadataMachineReadableCodeObject objects.
 This block is automatically set when you call startScanningWithResultBlock:
 */
@property (nonatomic, copy) void (^resultBlock)(NSArray *codes);

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
 *  This method assumes you have already set the `resultBlock` property directly.
 */
- (void)startScanning;

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

/**
 *  If using the front camera, switch to the back, or visa-versa.
 *  If this method is called when isScanning=NO, it has no effect
 */
- (void)flipCamera;

/**
 *  Return a BOOL value that specifies whether the current capture device has a torch.
 *
 *  @return YES if the the current capture device has a torch.
 */
- (BOOL)hasTorch;

/**
 *  Toggle the torch from on to off, or off to on.
 *  If the torch was previously set to Auto, the torch will turn on.
 *  If the device does not support a torch, calling this method will have no effect.
 *  To set the torch to on/off/auto directly, set the `torchMode` property.
 */
- (void)toggleTorch;

/**
 *  Freeze capture keeping the last frame on previewView.
 *  If this method is called before startScanning, it has no effect.
 */
- (void)freezeCapture;

/**
 *  Unfreeze a frozen capture
 */
- (void)unfreezeCapture;

@end
