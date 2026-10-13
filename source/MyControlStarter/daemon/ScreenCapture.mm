#import "ScreenCapture.h"
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOSurface/IOSurface.h>
#import <ImageIO/ImageIO.h>
#import <dlfcn.h>

typedef kern_return_t (*RenderDisplayFn)(mach_port_t, CFStringRef, IOSurfaceRef, int, int);
typedef CFTypeRef (*UICreateScreenImageFn)(void);
@interface ScreenCapture () { RenderDisplayFn _renderDisplay; UICreateScreenImageFn _uiCreateScreen; }
@property(nonatomic, readwrite) BOOL available;
@property(nonatomic, readwrite) CGSize pointSize;
@property(nonatomic, readwrite) CGSize pixelSize;
@end
@implementation ScreenCapture
- (instancetype)init {
    if ((self=[super init])) {
        UIScreen *s=[UIScreen mainScreen]; self.pointSize=s.bounds.size; CGSize n=s.nativeBounds.size; if(n.width<1||n.height<1)n=CGSizeMake(round(s.bounds.size.width*s.scale),round(s.bounds.size.height*s.scale)); self.pixelSize=n;
        void *qc=dlopen("/System/Library/Frameworks/QuartzCore.framework/QuartzCore",RTLD_NOW); if(qc)_renderDisplay=(RenderDisplayFn)dlsym(qc,"CARenderServerRenderDisplay");
        void *ui=dlopen("/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore",RTLD_NOW); if(ui)_uiCreateScreen=(UICreateScreenImageFn)dlsym(ui,"_UICreateScreenUIImage"); if(!_uiCreateScreen)_uiCreateScreen=(UICreateScreenImageFn)dlsym(RTLD_DEFAULT,"_UICreateScreenUIImage"); self.available=(_renderDisplay||_uiCreateScreen);
    } return self;
}
static NSData *enc(CGImageRef image,CGFloat q){if(!image)return nil;q=MAX(0.1,MIN(0.95,q));NSMutableData*out=[NSMutableData data];CGImageDestinationRef d=CGImageDestinationCreateWithData((__bridge CFMutableDataRef)out,CFSTR("public.jpeg"),1,NULL);if(!d)return nil;NSDictionary*o=@{(__bridge NSString*)kCGImageDestinationLossyCompressionQuality:@(q)};CGImageDestinationAddImage(d,image,(__bridge CFDictionaryRef)o);BOOL ok=CGImageDestinationFinalize(d);CFRelease(d);return ok?out:nil;}
- (NSData *)captureJPEGWithQuality:(CGFloat)q error:(NSError **)error {
    if(_renderDisplay){size_t w=(size_t)self.pixelSize.width,h=(size_t)self.pixelSize.height,bpr=((w*4)+63)&~((size_t)63);NSDictionary*p=@{(id)kIOSurfaceWidth:@(w),(id)kIOSurfaceHeight:@(h),(id)kIOSurfacePixelFormat:@((uint32_t)'BGRA'),(id)kIOSurfaceBytesPerElement:@4,(id)kIOSurfaceBytesPerRow:@(bpr),(id)kIOSurfaceAllocSize:@(bpr*h),(id)kIOSurfaceIsGlobal:@YES};IOSurfaceRef surf=IOSurfaceCreate((__bridge CFDictionaryRef)p);if(surf){kern_return_t kr=_renderDisplay(0,NULL,surf,0,0);if(kr==KERN_SUCCESS){IOSurfaceLock(surf,kIOSurfaceLockReadOnly,NULL);void*base=IOSurfaceGetBaseAddress(surf);CGColorSpaceRef cs=CGColorSpaceCreateDeviceRGB();CGDataProviderRef prov=base?CGDataProviderCreateWithData(NULL,base,bpr*h,NULL):NULL;CGImageRef img=prov?CGImageCreate(w,h,8,32,bpr,cs,kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder32Little,prov,NULL,false,kCGRenderingIntentDefault):NULL;NSData*j=img?enc(img,q):nil;if(img)CGImageRelease(img);if(prov)CGDataProviderRelease(prov);CGColorSpaceRelease(cs);IOSurfaceUnlock(surf,kIOSurfaceLockReadOnly,NULL);CFRelease(surf);if(j.length)return j;}else CFRelease(surf);}}
    if(_uiCreateScreen){UIImage*im=(__bridge_transfer UIImage*)_uiCreateScreen();if(im.CGImage){NSData*j=enc(im.CGImage,q);if(j.length)return j;}}
    if(error)*error=[NSError errorWithDomain:@"MyControl.Capture" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Screenshot unavailable"}];return nil;
}
@end
