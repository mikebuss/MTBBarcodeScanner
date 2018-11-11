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

/**
 *  Available torch modes when scanning barcodes.
 *
 *  While AVFoundation provides an additional automatic
 *  mode, it is not supported here because it only works
 *  with video recordings, not barcode scanning.
 */
typedef NS_ENUM(NSUInteger, MTBTorchMode) {
    MTBTorchModeOff,
    MTBTorchModeOn,
};

@interface MTBBarcodeScanner : NSObject

/**
 *  The currently set camera. See MTBCamera for options.
 *
 *  @sa setCamera:error:
 */
@property (nonatomic, assign, readonly) MTBCamera camera;

/**
 *  Control the torch on the device, if present.
 *
 *  Attempting to set the torch mode to an unsupported state
 *  will fail silently, and the value passed into the setter
 *  will be discarded.
 *
 *  @sa setTorchMode:error:
 */
@property (nonatomic, assign) MTBTorchMode torchMode;

/**
 *  Allow the user to tap the previewView to focus a specific area.
 *  Defaults to YES.
 */
@property (nonatomic, assign) BOOL allowTapToFocus;

/**
 *  If set, only barcodes inside this area will be scanned.
 *
 *  Setting this property is only supported while the scanner is active.
 *  Use the didStartScanningBlock if you want to set it as early as
 *  possible.
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
 
 The block is always called on the main queue.
 */
@property (nonatomic, copy) void (^didStartScanningBlock)(void);

/*!
 @property didTapToFocusBlock
 @abstract
 Block that's called when the user taps the screen to focus the camera. If allowsTapToFocus
 is set to NO, this will never be called.
 */
@property (nonatomic, copy) void (^didTapToFocusBlock)(CGPoint point);

/*!
 @property resultBlock
 @abstract
 Block that's called every time one or more barcodes are recognized.
 
 @discussion
 The resultBlock is called on the main queue once for every frame that at least one valid barcode is found.

 This block is automatically set when you call startScanningWithResultBlock:
 */
@property (nonatomic, copy) void (^resultBlock)(NSArray<AVMetadataMachineReadableCodeObject *> *codes);

/*!
 @property preferredAutoFocusRangeRestriction
 @abstract
 Auto focus range restriction, if supported.

 @discussion
 Defaults to AVCaptureAutoFocusRangeRestrictionNear. Will be ignored on unsupported devices.
 */
@property (nonatomic, assign) AVCaptureAutoFocusRangeRestriction preferredAutoFocusRangeRestriction;

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
- (instancetype)initWithMetadataObjectTypes:(NSArray<NSString *> *)metaDataObjectTypes
                                previewView:(UIView *)previewView;

/**
 *  Returns whether any camera exists in this device.
 *  Be aware that this returns NO if camera access is restricted.
 *
 *  @return YES if the device has a camera and authorization state is not AVAuthorizationStatusRestricted
 */
+ (BOOL)cameraIsPresent;

/**
 *  You can use this flag to check whether flipCamera can potentially
 *  be successful. You may want to hide your button to flip the camera
 *  if the device only has one camera.
 *
 *  @return YES if a second camera is present and authorization state is not AVAuthorizationStatusRestricted.
 *  @sa flipCamera
 */
- (BOOL)hasOppositeCamera;

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
 *
 *  This method returns quickly and does not wait for the internal session to
 *  start. Set the didStartScanningBlock to get a callback when the session
 *  is ready, i.e., a camera picture is visible.
 *
 *  @param error Error supplied if the scanning could not start.
 *
 *  @return YES if scanning started successfully, NO if there was an error.
 */
- (BOOL)startScanningWithError:(NSError **)error;

/**
 *  Start scanning for barcodes. The camera input will be added as a sublayer
 *  to the UIView given for previewView during initialization.
 *
 *  This method returns quickly and does not wait for the internal session to
 *  start. Set the didStartScanningBlock to get a callback when the session
 *  is ready, i.e., a camera picture is visible.
 *
 *  @param resultBlock Callback block for captured codes. If the scanner was instantiated with initWithMetadataObjectTypes:previewView, only codes with a type given in metaDataObjectTypes will be reported.
 *  @param error Error supplied if the scanning could not start.
 *
 *  @return YES if scanning started successfully, NO if there was an error.
 */
- (BOOL)startScanningWithResultBlock:(void (^)(NSArray<AVMetadataMachineReadableCodeObject *> *codes))resultBlock error:(NSError **)error;

/**
 *  Start scanning for barcodes using a specific camera. The camera input will be added as a sublayer
 *  to the UIView given for previewView during initialization.
 *
 *  This method returns quickly and does not wait for the internal session to
 *  start. Set the didStartScanningBlock to get a callback when the session
 *  is ready, i.e., a camera picture is visible.
 *
 *  @param camera The camera to use when scanning starts.
 *  @param resultBlock Callback block for captured codes. If the scanner was instantiated with initWithMetadataObjectTypes:previewView, only codes with a type given in metaDataObjectTypes will be reported.
 *  @param error Error supplied if the scanning could not start.
 *  
 *
 *  @return YES if scanning started successfully, NO if there was an error.
 */
- (BOOL)startScanningWithCamera:(MTBCamera)camera resultBlock:(void (^)(NSArray<AVMetadataMachineReadableCodeObject *> *codes))resultBlock error:(NSError **)error;

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
 *
 *  If the opposite camera is not available, this method will do nothing.
 *
 *  @sa hasOppositeCamera
 */
- (void)flipCamera;

/**
 *  Sets the camera and ignores any errors.
 *
 *  Deprecated.
 *
 *  @sa setCamera:error:
 */
- (void)setCamera:(MTBCamera)camera NS_DEPRECATED_IOS(2.0, 2.0, "Use setCamera:error: instead");

/**
 *  Sets the camera. This operation may fail, e.g., when the device
 *  does not have the specified camera.
 *
 *  @param camera The camera to use, see MTBCamera for options.
 *  @error Any error that occurred while trying to set the camera.
 *  @return YES, if the specified camera was set successfully, NO if any error occurred.
 */
- (BOOL)setCamera:(MTBCamera)camera error:(NSError **)error;

/**
 *  If using the front camera, switch to the back, or visa-versa.
 *
 *  If this method is called when (isScanning == NO), it will return
 *  NO and provide an error.
 *
 *  If the opposite camera is not available, the error parameter
 *  will explain the error.
 *
 *  @return YES if the camera was flipped, NO if any error occurred.
 */
- (BOOL)flipCameraWithError:(NSError **)error;

/**
 *  Return a BOOL value that specifies whether the current capture device has a torch.
 *
 *  @return YES if the the current capture device has a torch.
 */
- (BOOL)hasTorch;

/**
 *  Toggle the torch from on to off, or off to on.
 *  If the device does not support a torch or the opposite mode, calling
 *  this method will have no effect.
 *  To set the torch to on/off directly, set the `torchMode` property, or
 *  use setTorchMode:error: if you care about errors.
 */
- (void)toggleTorch;

/**
 *  Attempts to set a new torch mode.
 *
 *  @return YES, if setting the new mode was successful, and the torchMode
 *  property reflects the new state. NO if there was an error - use the 
 *  error parameter to learn about the reason.
 *
 *  @sa torchMode
 */
- (BOOL)setTorchMode:(MTBTorchMode)torchMode error:(NSError **)error;

/**
 *  Freeze capture keeping the last frame on previewView.
 *  If this method is called before startScanning, it has no effect.
 *
 *  Returns immediately – actually freezing the capture is
 *  done asynchronously.
 */
- (void)freezeCapture;

/**
 *  Unfreeze a frozen capture.
 *
 *  Returns immediately – actually unfreezing the capture is
 *  done asynchronously.
 */
- (void)unfreezeCapture;

/**
 *  Captures a still image of the current camera feed
 */
- (void)captureStillImage:(void (^)(UIImage *image, NSError *error))captureBlock;

/**
 *  Determine if currently capturing a still image
 */
- (BOOL)isCapturingStillImage;

@end
