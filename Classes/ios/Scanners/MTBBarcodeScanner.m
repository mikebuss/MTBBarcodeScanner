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

+ (BOOL)scanningIsAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock {
    NSAssert([MTBBarcodeScanner scanningIsAvailable], @"Scanning is not available on this device. \
             Check scanningIsAvailable: method before calling startScanningWithResultBlock:");
    self.resultBlock = resultBlock;
    [self.session startRunning];
    [self.previewView.layer addSublayer:self.capturePreviewLayer];
}

- (void)stopScanning {
    if ([MTBBarcodeScanner scanningIsAvailable]) {
        [self.session stopRunning];
        [self.capturePreviewLayer removeFromSuperlayer];
        
        self.resultBlock = nil;
        self.capturePreviewLayer = nil;
        self.captureDevice = nil;
        self.session = nil;
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
    }
}

#pragma mark - Session Configuration

- (AVCaptureSession *)session {
    if (!_session) {
        NSError *inputError = nil;
        _session = [[AVCaptureSession alloc] init];
        AVCaptureDevice *captureDevice = self.captureDevice;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                            error:&inputError];
        
        if (input) {
            // Set an optimized preset for barcode scanning
            [_session setSessionPreset:AVCaptureSessionPreset640x480];
            [_session addInput:input];
            
            AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
            [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [_session addOutput:captureOutput];
            captureOutput.metadataObjectTypes = self.metaDataObjectTypes;
            
            self.capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
            self.capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.capturePreviewLayer.frame = self.previewView.bounds;
            
            [_session commitConfiguration];
        } else {
            NSLog(@"Error adding AVCaptureDeviceInput to AVCaptureSession: %@", inputError);
        }
    }
    return _session;
}

- (AVCaptureDevice *)captureDevice {
    if (!_captureDevice) {
        NSError *lockError = nil;
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([_captureDevice lockForConfiguration:&lockError] == YES) {
            
            // Prioritize the focus on objects near to the device
            if ([_captureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
                _captureDevice.isAutoFocusRangeRestrictionSupported) {
                _captureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
            }
            
            // Focus on the center of the image
            if ([_captureDevice respondsToSelector:@selector(isFocusPointOfInterestSupported)] &&
                _captureDevice.isFocusPointOfInterestSupported) {
                _captureDevice.focusPointOfInterest = CGPointMake(kFocalPointOfInterestX, kFocalPointOfInterestY);
            }
            
            [_captureDevice unlockForConfiguration];
        }
    }
    return _captureDevice;
}

#pragma mark - Default Values

- (NSArray *)defaultMetaDataObjectTypes {
    return @[AVMetadataObjectTypeQRCode,
             AVMetadataObjectTypeUPCECode,
             AVMetadataObjectTypeCode39Code,
             AVMetadataObjectTypeCode39Mod43Code,
             AVMetadataObjectTypeEAN13Code,
             AVMetadataObjectTypeEAN8Code,
             AVMetadataObjectTypeCode93Code,
             AVMetadataObjectTypeCode128Code,
             AVMetadataObjectTypePDF417Code,
             AVMetadataObjectTypeAztecCode];
}

#pragma mark - Helper Methods

- (void)addRotationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceOrientationDidChangeNotification:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


@end
