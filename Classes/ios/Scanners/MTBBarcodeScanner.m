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
@property (strong, nonatomic) AVCaptureSession *session;

/*!
 @property captureDevice
 @abstract
 Object that represents the physical camera on the device.
 */
@property (strong, nonatomic) AVCaptureDevice *captureDevice;

/*!
 @property capturePreviewLayer
 @abstract
 The layer used to view the camera input. This layer is added to the
 previewView when scanning starts.
 */
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *capturePreviewLayer;

/*!
 @property metaDataObjectTypes
 @abstract
 The MetaDataObjectTypes to look for in the scanning session.
 
 @discussion
 Only objects with a MetaDataObjectType found in this array will be
 reported to the result block.
 */
@property (strong, nonatomic) NSArray *metaDataObjectTypes;

/*!
 @property previewView
 @abstract
 The view used to preview the camera input.
 
 @discussion
 The AVCaptureVideoPreviewLayer is added to this view to preview the
 camera input when scanning starts. When scanning stops, the layer is
 removed.
 */
@property (weak, nonatomic) UIView *previewView;

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
    NSParameterAssert(previewView);
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
    NSParameterAssert(previewView);
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
    
    if (!self.hasExistingSession){
        self.captureDevice = [self newCaptureDevice];
        self.session = [self newSession];
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
            
            for(AVCaptureInput *input in self.session.inputs) {
                [self.session removeInput:input];
            }
            
            for(AVCaptureOutput *output in self.session.outputs) {
                [self.session removeOutput:output];
            }
            
            [self.session stopRunning];
            self.session = nil;
            self.resultBlock = nil;
            self.capturePreviewLayer = nil;
            self.captureDevice = nil;
        });
    }
}

- (BOOL)isScanning {
    return [self.session isRunning];
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

- (AVCaptureSession *)newSession {
    AVCaptureSession *newSession = nil;
    NSError *inputError = nil;
    newSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *captureDevice = self.captureDevice;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                        error:&inputError];
    
    if (input) {
        // Set an optimized preset for barcode scanning
        [newSession setSessionPreset:AVCaptureSessionPreset640x480];
        [newSession addInput:input];
        
        AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
        [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [newSession addOutput:captureOutput];
        captureOutput.metadataObjectTypes = self.metaDataObjectTypes;
        
        self.capturePreviewLayer = nil;
        self.capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:newSession];
        self.capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.capturePreviewLayer.frame = self.previewView.bounds;
        
        [newSession commitConfiguration];
    } else {
        NSLog(@"Error adding AVCaptureDeviceInput to AVCaptureSession: %@", inputError);
    }
    
    return newSession;
}

- (AVCaptureDevice *)newCaptureDevice {
    
    AVCaptureDevice *newCaptureDevice = nil;
    NSError *lockError = nil;
    newCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([newCaptureDevice lockForConfiguration:&lockError] == YES) {
        
        // Prioritize the focus on objects near to the device
        if ([newCaptureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
            newCaptureDevice.isAutoFocusRangeRestrictionSupported) {
            newCaptureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        
        // Focus on the center of the image
        if ([newCaptureDevice respondsToSelector:@selector(isFocusPointOfInterestSupported)] &&
            newCaptureDevice.isFocusPointOfInterestSupported) {
            newCaptureDevice.focusPointOfInterest = CGPointMake(kFocalPointOfInterestX, kFocalPointOfInterestY);
        }
        
        [newCaptureDevice unlockForConfiguration];
    }
    
    return newCaptureDevice;
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


@end
