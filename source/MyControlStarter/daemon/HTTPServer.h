#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface HTTPServer : NSObject
- (instancetype)initWithPort:(uint16_t)port;
- (void)start;
@end
NS_ASSUME_NONNULL_END
