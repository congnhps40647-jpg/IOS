#import "MCWebViewController.h"
#import <WebKit/WebKit.h>

@interface MCWebViewController ()
@property(nonatomic, strong) WKWebView *webView;
@end

@implementation MCWebViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Control";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    NSString *tokenPath = @"/var/mobile/Library/MyControl/token.txt";
    NSString *token = [[NSString stringWithContentsOfFile:tokenPath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSString *frag = [token stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet] ?: @"";
    NSString *urlString = [NSString stringWithFormat:@"http://127.0.0.1:9999/#%@", frag];
    NSURL *url = [NSURL URLWithString:urlString];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0]];
}
@end
