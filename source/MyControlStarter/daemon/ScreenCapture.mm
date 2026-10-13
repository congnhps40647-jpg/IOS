#import "ScreenCapture.h"
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <dlfcn.h>

typedef CFTypeRef (*UICreateScreenImageFn)(void);

@interface ScreenCapture () {
    UICreateScreenImageFn _uiCreateScreen;
}
@property(nonatomic, readwrite) BOOL available;
@property(nonatomic, readwrite) CGSize pointSize;
@property(nonatomic, readwrite) CGSize pixelSize;
@end

@implementation ScreenCapture

- (instancetype)init {
    if ((self = [super init])) {
        UIScreen *screen = [UIScreen mainScreen];
        self.pointSize = screen.bounds.size;
        CGSize native = screen.nativeBounds.size;
        if (native.width < 1 || native.height < 1) {
            native = CGSizeMake(round(screen.bounds.size.width * screen.scale),
                                round(screen.bounds.size.height * screen.scale));
        }
        self.pixelSize = native;

        void *ui = dlopen("/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore", RTLD_NOW);
        if (ui) _uiCreateScreen = (UICreateScreenImageFn)dlsym(ui, "_UICreateScreenUIImage");
        if (!_uiCreateScreen) _uiCreateScreen = (UICreateScreenImageFn)dlsym(RTLD_DEFAULT, "_UICreateScreenUIImage");
        self.available = (_uiCreateScreen != NULL);
    }
    return self;
}

static NSData *encodeJPEG(CGImageRef image, CGFloat quality) {
    if (!image) return nil;
    quality = MAX(0.1, MIN(0.95, quality));
    NSMutableData *out = [NSMutableData data];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)out, CFSTR("public.jpeg"), 1, NULL);
    if (!dest) return nil;
    NSDictionary *opts = @{ (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(quality) };
    CGImageDestinationAddImage(dest, image, (__bridge CFDictionaryRef)opts);
    BOOL ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return ok ? out : nil;
}

- (NSData *)captureJPEGWithQuality:(CGFloat)quality error:(NSError **)error {
    if (_uiCreateScreen) {
        UIImage *image = (__bridge_transfer UIImage *)_uiCreateScreen();
        if (image.CGImage) {
            NSData *jpeg = encodeJPEG(image.CGImage, quality);
            if (jpeg.length) return jpeg;
        }
    }
    if (error) {
        *error = [NSError errorWithDomain:@"MyControl.Capture"
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"Screenshot backend unavailable on this device"}];
    }
    return nil;
}

@end
