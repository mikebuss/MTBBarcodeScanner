//
//  MTBBarcodeScanner.m
//  MTBBarcodeScannerExample
//
//  Created by Mike Buss on 2/8/14.
//
//

#import <QuartzCore/QuartzCore.h>
#import "MTBBarcodeScanner.h"

@interface MTBBarcodeScanner () <AVCaptureMetadataOutputObjectsDelegate>
/*!
 @property session
 @abstract
 The capture session used for scanning barcodes.
 */
@property (nonatomic, strong) AVCaptureSession *session;

/*!
 @property capturePreviewLayer
 @abstract
 The layer used to view the camera input. This layer is added to the
 previewView when scanning starts.
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *capturePreviewLayer;

/*!
 @property currentCaptureDeviceInput
 @abstract
 The current capture device input for capturing video. This is used
 to reset the camera to its initial properties when scanning stops.
 */
@property (nonatomic, strong) AVCaptureDeviceInput *currentCaptureDeviceInput;

/*!
 @property metaDataObjectTypes
 @abstract
 The MetaDataObjectTypes to look for in the scanning session.
 
 @discussion
 Only objects with a MetaDataObjectType found in this array will be
 reported to the result block.
 */
@property (nonatomic, strong) NSArray *metaDataObjectTypes;

/*!
 @property previewView
 @abstract
 The view used to preview the camera input.
 
 @discussion
 The AVCaptureVideoPreviewLayer is added to this view to preview the
 camera input when scanning starts. When scanning stops, the layer is
 removed.
 */
@property (nonatomic, weak) UIView *previewView;

/*!
 @property resultBlock
 @abstract
 Block that's called for every barcode captured. Returns an array of AVMetadataMachineReadableCodeObjects.
 
 @discussion
 The resultBlock is called once for every frame that at least one valid barcode is found.
 The returned array consists of AVMetadataMachineReadableCodeObject objects.
 */
@property (nonatomic, copy) void (^resultBlock)(NSArray *codes);

/*!
 @property hasExistingSession
 @abstract
 BOOL that is set to YES when a new valid session is created and set to NO when stopScanning
 is called.
 
 @discussion
 stopScanning now discards the session asynchronously and hasExistingSession is set to NO before
 that block is called. If startScanning is called while the discard block is still in progress
 hasExistingSession will be NO so we can create a new session instead of attempting to use
 the session that is being discarded.
 */

@property (nonatomic, assign) BOOL hasExistingSession;

/*!
 @property initialAutoFocusRangeRestriction
 @abstract
 The auto focus range restriction the AVCaptureDevice was initially configured for when scanning started.
 
 @discussion
 Then startScanning is called, the auto focus range restriction of the default AVCaptureDevice
 is stored. When stopScanning is called, the AVCaptureDevice is reset to the initial range restriction
 to prevent a bug in the AVFoundation framework.
 */
@property (nonatomic, assign) AVCaptureAutoFocusRangeRestriction initialAutoFocusRangeRestriction;

/*!
 @property initialFocusPoint
 @abstract
 The focus point the AVCaptureDevice was initially configured for when scanning started.
 
 @discussion
 Then startScanning is called, the focus point of the default AVCaptureDevice
 is stored. When stopScanning is called, the AVCaptureDevice is reset to the initial focal point
 to prevent a bug in the AVFoundation framework.
 */
@property (nonatomic, assign) CGPoint initialFocusPoint;

@end

CGFloat const kFocalPointOfInterestX = 0.5;
CGFloat const kFocalPointOfInterestY = 0.5;

@implementation MTBBarcodeScanner

#pragma mark - Lifecycle

- (instancetype)init {
    NSAssert(NO, @"MTBBarcodeScanner init is not supported. Please use initWithPreviewView: \
             or initWithMetadataObjectTypes:previewView: to instantiate a MTBBarcodeScanner");
    return nil;
}

- (instancetype)initWithPreviewView:(UIView *)previewView {
    self = [super init];
    if (self) {
        _previewView = previewView;
        _metaDataObjectTypes = [self defaultMetaDataObjectTypes];
        [self addRotationObserver];
    }
    return self;
}

- (instancetype)initWithMetadataObjectTypes:(NSArray *)metaDataObjectTypes
                                previewView:(UIView *)previewView {
    NSParameterAssert(metaDataObjectTypes);
    NSAssert(metaDataObjectTypes.count > 0,
             @"Must initialize MTBBarcodeScanner with at least one metaDataObjectTypes value.");
    
    self = [super init];
    if (self) {
        NSAssert(!([metaDataObjectTypes indexOfObject:AVMetadataObjectTypeFace] != NSNotFound),
                 @"The type %@ is not supported by MTBBarcodeScanner.", AVMetadataObjectTypeFace);
        
        _metaDataObjectTypes = metaDataObjectTypes;
        _previewView = previewView;
        [self addRotationObserver];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Scanning

+ (BOOL)cameraIsPresent {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

+ (BOOL)scanningIsProhibited {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

+ (void)requestCameraPermissionWithSuccess:(void (^)(BOOL success))successBlock {
    if (![self cameraIsPresent]) {
        successBlock(NO);
        return;
    }
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            successBlock(YES);
            break;
            
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            successBlock(NO);
            break;
            
        case AVAuthorizationStatusNotDetermined:
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                     completionHandler:^(BOOL granted) {
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             successBlock(granted);
                                         });
                                         
                                     }];
            break;
    }
}

- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock {
    NSAssert([MTBBarcodeScanner cameraIsPresent], @"Attempted to start scanning on a device with no camera. Check requestCameraPermissionWithSuccess: method before calling startScanningWithResultBlock:");
    NSAssert(![MTBBarcodeScanner scanningIsProhibited], @"Scanning is prohibited on this device. \
             Check requestCameraPermissionWithSuccess: method before calling startScanningWithResultBlock:");
    
    self.resultBlock = resultBlock;
    
    if (!self.hasExistingSession) {
        AVCaptureDevice *captureDevice = [self newCaptureDeviceWithCamera:self.camera];
        self.session = [self newSessionWithCaptureDevice:captureDevice];
        self.hasExistingSession = YES;
    }
    
    [self.session startRunning];
    self.capturePreviewLayer.cornerRadius = self.previewView.layer.cornerRadius;
    [self.previewView.layer addSublayer:self.capturePreviewLayer];
    [self refreshVideoOrientation];
}

- (void)stopScanning {
    if (self.hasExistingSession) {
        
        self.hasExistingSession = NO;
        [self.capturePreviewLayer removeFromSuperlayer];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // When we're finished scanning, reset the settings for the camera
            // to their orignal states
            [self removeDeviceInput];
            
            for (AVCaptureOutput *output in self.session.outputs) {
                [self.session removeOutput:output];
            }
            
            [self.session stopRunning];
            self.session = nil;
            self.resultBlock = nil;
            self.capturePreviewLayer = nil;
        });
    }
}

- (BOOL)isScanning {
    return [self.session isRunning];
}

- (void)flipCamera {
    if (self.isScanning) {
        if (self.camera == MTBCameraFront) {
            self.camera = MTBCameraBack;
        } else {
            self.camera = MTBCameraFront;
        }
    }
}

#pragma mark - AVCaptureMetadataOutputObjects Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    NSMutableArray *codes = [[NSMutableArray alloc] init];
    
    for (AVMetadataObject *metaData in metadataObjects) {
        AVMetadataMachineReadableCodeObject *barCodeObject = (AVMetadataMachineReadableCodeObject *)[self.capturePreviewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metaData];
        if (barCodeObject) {
            [codes addObject:barCodeObject];
        }
    }
    
    if (self.resultBlock) {
        self.resultBlock(codes);
    }
}

#pragma mark - Rotation

- (void)handleDeviceOrientationDidChangeNotification:(NSNotification *)notification {
    [self refreshVideoOrientation];
}

- (void)refreshVideoOrientation {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    self.capturePreviewLayer.frame = self.previewView.bounds;
    if ([self.capturePreviewLayer.connection isVideoOrientationSupported]) {
        self.capturePreviewLayer.connection.videoOrientation = [self captureOrientationForInterfaceOrientation:orientation];
    }
}

- (AVCaptureVideoOrientation)captureOrientationForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

#pragma mark - Session Configuration

- (AVCaptureSession *)newSessionWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    AVCaptureSession *newSession = [[AVCaptureSession alloc] init];
    
    AVCaptureDeviceInput *input = [self deviceInputForCaptureDevice:captureDevice];
    [self setDeviceInput:input session:newSession];
    
    // Set an optimized preset for barcode scanning
    [newSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [newSession addOutput:captureOutput];
    captureOutput.metadataObjectTypes = self.metaDataObjectTypes;
    
    self.capturePreviewLayer = nil;
    self.capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:newSession];
    self.capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.capturePreviewLayer.frame = self.previewView.bounds;
    
    [newSession commitConfiguration];
    
    return newSession;
}

- (AVCaptureDeviceInput *)deviceInputForCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSError *inputError = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                        error:&inputError];
    return input;
}

- (AVCaptureDevice *)newCaptureDeviceWithCamera:(MTBCamera)camera {
    AVCaptureDevice *newCaptureDevice = nil;
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevicePosition position = [self devicePositionForCamera:camera];
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == position) {
            newCaptureDevice = device;
            break;
        }
    }
    
    // If the front camera is not available, use the back camera
    if (!newCaptureDevice) {
        newCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return newCaptureDevice;
}

- (AVCaptureDevicePosition)devicePositionForCamera:(MTBCamera)camera {
    switch (camera) {
        case MTBCameraFront:
            return AVCaptureDevicePositionFront;
        case MTBCameraBack:
            return AVCaptureDevicePositionBack;
        default:
            return AVCaptureDevicePositionUnspecified;
            break;
    }
}

#pragma mark - Default Values

- (NSArray *)defaultMetaDataObjectTypes {
    NSMutableArray *types = [@[AVMetadataObjectTypeQRCode,
                               AVMetadataObjectTypeUPCECode,
                               AVMetadataObjectTypeCode39Code,
                               AVMetadataObjectTypeCode39Mod43Code,
                               AVMetadataObjectTypeEAN13Code,
                               AVMetadataObjectTypeEAN8Code,
                               AVMetadataObjectTypeCode93Code,
                               AVMetadataObjectTypeCode128Code,
                               AVMetadataObjectTypePDF417Code,
                               AVMetadataObjectTypeAztecCode] mutableCopy];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        [types addObjectsFromArray:@[
                                     AVMetadataObjectTypeInterleaved2of5Code,
                                     AVMetadataObjectTypeITF14Code,
                                     AVMetadataObjectTypeDataMatrixCode
                                     ]];
    }
    
    return types;
}

#pragma mark - Helper Methods

- (void)addRotationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceOrientationDidChangeNotification:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)setDeviceInput:(AVCaptureDeviceInput *)deviceInput session:(AVCaptureSession *)session {
    [self removeDeviceInput];
    
    self.currentCaptureDeviceInput = deviceInput;
    
    if ([deviceInput.device lockForConfiguration:nil] == YES) {
        
        // Prioritize the focus on objects near to the device
        if ([deviceInput.device respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
            deviceInput.device.isAutoFocusRangeRestrictionSupported) {
            
            self.initialAutoFocusRangeRestriction = deviceInput.device.autoFocusRangeRestriction;
            deviceInput.device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        
        // Focus on the center of the image
        if ([deviceInput.device respondsToSelector:@selector(isFocusPointOfInterestSupported)] &&
            deviceInput.device.isFocusPointOfInterestSupported) {
            
            self.initialFocusPoint = deviceInput.device.focusPointOfInterest;
            deviceInput.device.focusPointOfInterest = CGPointMake(kFocalPointOfInterestX, kFocalPointOfInterestY);
        }
        
        [deviceInput.device unlockForConfiguration];
    }
    
    [session addInput:deviceInput];
}

- (void)removeDeviceInput {
    
    AVCaptureDeviceInput *deviceInput = self.currentCaptureDeviceInput;
    
    // Restore focus settings to the previously saved state
    if ([deviceInput.device lockForConfiguration:nil] == YES) {
        if ([deviceInput.device respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
            deviceInput.device.isAutoFocusRangeRestrictionSupported) {
            deviceInput.device.autoFocusRangeRestriction = self.initialAutoFocusRangeRestriction;
        }
        
        if ([deviceInput.device respondsToSelector:@selector(isFocusPointOfInterestSupported)] &&
            deviceInput.device.isFocusPointOfInterestSupported) {
            deviceInput.device.focusPointOfInterest = self.initialFocusPoint;
        }
        
        [deviceInput.device unlockForConfiguration];
    }
    
    [self.session removeInput:deviceInput];
    self.currentCaptureDeviceInput = nil;
}

#pragma mark - Setters

- (void)setCamera:(MTBCamera)camera {
    
    if (self.isScanning && camera != _camera) {
        AVCaptureDevice *captureDevice = [self newCaptureDeviceWithCamera:camera];
        AVCaptureDeviceInput *input = [self deviceInputForCaptureDevice:captureDevice];
        [self setDeviceInput:input session:self.session];
    }
    
    _camera = camera;
}

@end
