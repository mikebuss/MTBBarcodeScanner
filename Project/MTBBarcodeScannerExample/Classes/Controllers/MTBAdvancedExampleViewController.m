//
//  MTBAdvancedExampleViewController.m
//  MTBBarcodeScannerExample
//
//  Created by Mike Buss on 2/10/14.
//
//

#import "MTBAdvancedExampleViewController.h"
#import "MTBBarcodeScanner.h"

@interface MTBAdvancedExampleViewController ()
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *toggleScanningButton;
@property (weak, nonatomic) IBOutlet UILabel *instructions;
@property (strong, nonatomic) MTBBarcodeScanner *scanner;
@property (strong, nonatomic) NSMutableDictionary *overlayViews;
@property (nonatomic) BOOL didShowAlert;
@end

@implementation MTBAdvancedExampleViewController

#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didShowAlert && !self.instructions) {
        [[[UIAlertView alloc] initWithTitle:@"Example"
                                    message:@"To view this example, point the camera at the sample barcodes on the official MTBBarcodeScanner README."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.scanner stopScanning];
    [super viewWillDisappear:animated];
}

#pragma mark - Scanner

- (MTBBarcodeScanner *)scanner {
    if (!_scanner) {
        _scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:_previewView];
    }
    return _scanner;
}

#pragma mark - Overlay Views

- (NSMutableDictionary *)overlayViews {
    if (!_overlayViews) {
        _overlayViews = [[NSMutableDictionary alloc] init];
    }
    return _overlayViews;
}

#pragma mark - Scanning

- (void)startScanning {
    [self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        [self drawOverlaysOnCodes:codes];
    }];
    
    [self.toggleScanningButton setTitle:@"Stop Scanning" forState:UIControlStateNormal];
    self.toggleScanningButton.backgroundColor = [UIColor redColor];
}

- (void)drawOverlaysOnCodes:(NSArray *)codes {
    // Get all of the captured code strings
    NSMutableArray *codeStrings = [[NSMutableArray alloc] init];
    for (AVMetadataMachineReadableCodeObject *code in codes) {
        if (code.stringValue) {
            [codeStrings addObject:code.stringValue];
        }
    }
    
    // Remove any code overlays no longer on the screen
    for (NSString *code in self.overlayViews.allKeys) {
        if ([codeStrings indexOfObject:code] == NSNotFound) {
            // A code that was on the screen is no longer
            // in the list of captured codes, remove its overlay
            [self.overlayViews[code] removeFromSuperview];
            [self.overlayViews removeObjectForKey:code];
        }
    }
    
    for (AVMetadataMachineReadableCodeObject *code in codes) {
        UIView *view = nil;
        NSString *codeString = code.stringValue;
        
        if (codeString) {
            if (self.overlayViews[codeString]) {
                // The overlay is already on the screen
                view = self.overlayViews[codeString];
                
                // Move it to the new location
                view.frame = code.bounds;
                
            } else {
                // First time seeing this code
                BOOL isValidCode = [self isValidCodeString:codeString];
                
                // Create an overlay
                UIView *overlayView = [self overlayForCodeString:codeString
                                                          bounds:code.bounds
                                                           valid:isValidCode];
                self.overlayViews[codeString] = overlayView;
                
                // Add the overlay to the preview view
                [self.previewView addSubview:overlayView];
                
            }
        }
    }
}

- (BOOL)isValidCodeString:(NSString *)codeString {
    BOOL stringIsValid = ([codeString rangeOfString:@"Valid"].location != NSNotFound);
    return stringIsValid;
}

- (UIView *)overlayForCodeString:(NSString *)codeString bounds:(CGRect)bounds valid:(BOOL)valid {
    UIColor *viewColor = valid ? [UIColor greenColor] : [UIColor redColor];
    UIView *view = [[UIView alloc] initWithFrame:bounds];
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    
    // Configure the view
    view.layer.borderWidth = 5.0;
    view.backgroundColor = [viewColor colorWithAlphaComponent:0.75];
    view.layer.borderColor = viewColor.CGColor;
    
    // Configure the label
    label.font = [UIFont boldSystemFontOfSize:12];
    label.text = codeString;
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    
    // Add constraints to label to improve text size?
    
    // Add the label to the view
    [view addSubview:label];
    
    return view;
}

- (void)stopScanning {
    [self.scanner stopScanning];
    
    [self.toggleScanningButton setTitle:@"Start Scanning" forState:UIControlStateNormal];
    self.toggleScanningButton.backgroundColor = self.view.tintColor;
    
    for (NSString *code in self.overlayViews.allKeys) {
        [self.overlayViews[code] removeFromSuperview];
    }
}

#pragma mark - Actions

- (IBAction)toggleScanningTapped:(id)sender {
    if (![MTBBarcodeScanner scanningIsAvailableAndAllowed]) {
        [[[UIAlertView alloc] initWithTitle:@"Scanning Unavailable"
                                    message:@"Barcode scanning is unavailable on this device."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        return;
    }
    
    if (![self.scanner isScanning]) {
        [self startScanning];
    } else {
        [self stopScanning];
    }
}

- (void)backTapped {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
