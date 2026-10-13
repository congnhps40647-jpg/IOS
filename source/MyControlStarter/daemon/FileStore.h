#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface FileStore : NSObject
+ (NSString *)baseDirectory;
+ (NSString *)webDirectory;
+ (NSString *)scriptsDirectory;
+ (void)ensureDirectories;
+ (BOOL)saveScriptNamed:(NSString *)name content:(NSString *)content error:(NSError **)error;
+ (nullable NSString *)loadScriptNamed:(NSString *)name error:(NSError **)error;
+ (NSArray<NSString *> *)listScripts;
@end
NS_ASSUME_NONNULL_END
