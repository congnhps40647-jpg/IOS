#import "MCAppDelegate.h"
#import "MCWebViewController.h"

@implementation MCAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];

    MCWebViewController *control = [MCWebViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:control];
    self.window.rootViewController = nav;

    [self.window makeKeyAndVisible];
    return YES;
}
@end
