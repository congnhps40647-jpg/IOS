#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ScriptRunner : NSObject
+ (NSDictionary *)runLuaSource:(NSString *)source;
@end
NS_ASSUME_NONNULL_END
