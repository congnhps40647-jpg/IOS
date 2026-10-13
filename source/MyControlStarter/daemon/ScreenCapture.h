#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
@interface ScreenCapture : NSObject
@property(nonatomic, readonly) BOOL available;
@property(nonatomic, readonly) CGSize pointSize;
@property(nonatomic, readonly) CGSize pixelSize;
- (NSData *)captureJPEGWithQuality:(CGFloat)quality error:(NSError **)error;
@end
