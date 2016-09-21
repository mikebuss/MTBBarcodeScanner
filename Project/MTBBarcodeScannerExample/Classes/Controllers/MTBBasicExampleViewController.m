//
//  MTBViewController.m
//  MTBBarcodeScannerExample
//
//  Created by Mike Buss on 2/8/14.
//
//

#import "MTBBasicExampleViewController.h"
#import "MTBBarcodeScanner.h"

@interface MTBBasicExampleViewController () <UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UIView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *toggleScanningButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *toggleTorchButton;

@property (nonatomic, strong) MTBBarcodeScanner *scanner;
@property (nonatomic, strong) NSMutableArray *uniqueCodes;
@property (nonatomic, assign) BOOL captureIsFrozen;
@property (nonatomic, assign) BOOL didShowCaptureWarning;

@end

@implementation MTBBasicExampleViewController

#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewTapped)];
    [self.previewView addGestureRecognizer:tapGesture];
    
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

#pragma mark - Scanning

- (void)startScanning {
    self.uniqueCodes = [[NSMutableArray alloc] init];
    
    NSError *error = nil;
    [self.scanner startScanningWithResultBlock:^(NSArray *codes) {
        for (AVMetadataMachineReadableCodeObject *code in codes) {
            if (code.stringValue && [self.uniqueCodes indexOfObject:code.stringValue] == NSNotFound) {
                [self.uniqueCodes addObject:code.stringValue];
                
                NSLog(@"Found unique code: %@", code.stringValue);
                
                // Update the tableview
                [self.tableView reloadData];
                [self scrollToLastTableViewCell];
            }
        }
    } error:&error];
    
    if (error) {
        NSLog(@"An error occurred: %@", error.localizedDescription);
    }
    
    [self.toggleScanningButton setTitle:@"Stop Scanning" forState:UIControlStateNormal];
    self.toggleScanningButton.backgroundColor = [UIColor redColor];
}

- (void)stopScanning {
    [self.scanner stopScanning];
    
    [self.toggleScanningButton setTitle:@"Start Scanning" forState:UIControlStateNormal];
    self.toggleScanningButton.backgroundColor = self.view.tintColor;
    
    self.captureIsFrozen = NO;
}

#pragma mark - Actions

- (IBAction)toggleScanningTapped:(id)sender {
    if ([self.scanner isScanning] || self.captureIsFrozen) {
        [self stopScanning];
        self.toggleTorchButton.title = @"Enable Torch";
    } else {
        [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
            if (success) {
                [self startScanning];
            } else {
                [self displayPermissionMissingAlert];
            }
        }];
    }
}

- (IBAction)switchCameraTapped:(id)sender {
    [self.scanner flipCamera];
}

- (IBAction)toggleTorchTapped:(id)sender {
    if (self.scanner.torchMode == MTBTorchModeOff || self.scanner.torchMode == MTBTorchModeAuto) {
        self.scanner.torchMode = MTBTorchModeOn;
        self.toggleTorchButton.title = @"Disable Torch";
    } else {
        self.scanner.torchMode = MTBTorchModeOff;
        self.toggleTorchButton.title = @"Enable Torch";
    }
}

- (void)backTapped {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"BarcodeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.text = self.uniqueCodes[indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uniqueCodes.count;
}

#pragma mark - Helper Methods

- (void)displayPermissionMissingAlert {
    NSString *message = nil;
    if ([MTBBarcodeScanner scanningIsProhibited]) {
        message = @"This app does not have permission to use the camera.";
    } else if (![MTBBarcodeScanner cameraIsPresent]) {
        message = @"This device does not have a camera.";
    } else {
        message = @"An unknown error occurred.";
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Scanning Unavailable"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
}

- (void)scrollToLastTableViewCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.uniqueCodes.count - 1
                                                inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

#pragma mark - Gesture Handlers

- (void)previewTapped {
    if (![self.scanner isScanning] && !self.captureIsFrozen) {
        return;
    }
    
    if (!self.didShowCaptureWarning) {
        [[[UIAlertView alloc] initWithTitle:@"Capture Frozen"
                                    message:@"The capture is now frozen. Tap the preview again to unfreeze."
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        
        self.didShowCaptureWarning = YES;
    }
    
    if (self.captureIsFrozen) {
        [self.scanner unfreezeCapture];
    } else {
        [self.scanner freezeCapture];
    }
    
    self.captureIsFrozen = !self.captureIsFrozen;
}

#pragma mark - Setters

- (void)setUniqueCodes:(NSMutableArray *)uniqueCodes {
    _uniqueCodes = uniqueCodes;
    [self.tableView reloadData];
}

@end
