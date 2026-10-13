#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "FileStore.h"

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    @autoreleasepool {
        [FileStore ensureDirectories];
        NSLog(@"[MyControl] starting v0.3.0...");
        HTTPServer *server = [[HTTPServer alloc] initWithPort:9999];
        [server start];
    }
    return 0;
}
