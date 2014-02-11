//
//  MTBBarcodeScanner.h
//  MTBBarcodeScannerExample
//
//  Created by Mike Buss on 2/8/14.
//
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface MTBBarcodeScanner : NSObject

// Lifecycle
- (instancetype)initWithPreviewView:(UIView *)previewView;
- (instancetype)initWithMetadataObjectTypes:(NSArray *)metaDataObjectTypes
                                previewView:(UIView *)previewView;

// Scanning
+ (BOOL)scanningIsAvailable;
- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock;
- (void)stopScanning;
- (BOOL)isScanning;

@end
