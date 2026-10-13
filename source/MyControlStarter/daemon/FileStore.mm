#import "FileStore.h"
@implementation FileStore
+ (NSString *)baseDirectory{return @"/var/mobile/Library/MyControl";}
+ (NSString *)webDirectory{return [[self baseDirectory]stringByAppendingPathComponent:@"web"];}
+ (NSString *)scriptsDirectory{return [[self baseDirectory]stringByAppendingPathComponent:@"scripts"];}
+ (void)ensureDirectories{NSFileManager*fm=NSFileManager.defaultManager;[fm createDirectoryAtPath:[self webDirectory] withIntermediateDirectories:YES attributes:nil error:nil];[fm createDirectoryAtPath:[self scriptsDirectory] withIntermediateDirectories:YES attributes:nil error:nil];[fm createDirectoryAtPath:[[self baseDirectory]stringByAppendingPathComponent:@"tmp"] withIntermediateDirectories:YES attributes:nil error:nil];}
+ (NSString *)safeName:(NSString*)name{NSString*last=name.lastPathComponent.length?name.lastPathComponent:@"script.lua";if(![last.pathExtension.lowercaseString isEqualToString:@"lua"])last=[last stringByAppendingPathExtension:@"lua"];return last;}
+ (BOOL)saveScriptNamed:(NSString*)name content:(NSString*)content error:(NSError**)error{[self ensureDirectories];return [content writeToFile:[[self scriptsDirectory]stringByAppendingPathComponent:[self safeName:name]] atomically:YES encoding:NSUTF8StringEncoding error:error];}
+ (NSString *)loadScriptNamed:(NSString*)name error:(NSError**)error{return [NSString stringWithContentsOfFile:[[self scriptsDirectory]stringByAppendingPathComponent:[self safeName:name]] encoding:NSUTF8StringEncoding error:error];}
+ (NSArray<NSString*>*)listScripts{[self ensureDirectories];NSArray*items=[NSFileManager.defaultManager contentsOfDirectoryAtPath:[self scriptsDirectory] error:nil]?:@[];NSPredicate*p=[NSPredicate predicateWithBlock:^BOOL(NSString*n,NSDictionary*_){return [n.pathExtension.lowercaseString isEqualToString:@"lua"];}];return [[items filteredArrayUsingPredicate:p]sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];}
@end
