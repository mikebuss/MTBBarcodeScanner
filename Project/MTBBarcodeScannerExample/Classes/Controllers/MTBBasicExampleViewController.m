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
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *toggleScanningButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MTBBarcodeScanner *scanner;
@property (strong, nonatomic) NSMutableArray *uniqueCodes;
@end

@implementation MTBBasicExampleViewController

#pragma mark - Properties

- (void)setUniqueCodes:(NSMutableArray *)uniqueCodes {
    _uniqueCodes = uniqueCodes;
    [self.tableView reloadData];
}

#pragma mark - Lifecycle

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
    }];
    
    [self.toggleScanningButton setTitle:@"Stop Scanning" forState:UIControlStateNormal];
    self.toggleScanningButton.backgroundColor = [UIColor redColor];
}

- (void)stopScanning {
    [self.scanner stopScanning];
    
    [self.toggleScanningButton setTitle:@"Start Scanning" forState:UIControlStateNormal];
    self.toggleScanningButton.backgroundColor = self.view.tintColor;
}

#pragma mark - Actions

- (IBAction)toggleScanningTapped:(id)sender {
    if (![MTBBarcodeScanner scanningIsAvailable]) {
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

- (void)scrollToLastTableViewCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.uniqueCodes.count - 1
                                                inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

@end
