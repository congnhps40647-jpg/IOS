#import "MCRootViewController.h"
#import "MCWebViewController.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface MCRootViewController ()
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UILabel *urlLabel;
@property(nonatomic, strong) UILabel *tokenLabel;
@end

@implementation MCRootViewController

- (NSString *)wifiIPv4 {
    struct ifaddrs *ifaddr = NULL;
    NSString *result = @"127.0.0.1";
    if (getifaddrs(&ifaddr) == 0) {
        for (struct ifaddrs *ifa = ifaddr; ifa; ifa = ifa->ifa_next) {
            if (!ifa->ifa_addr || ifa->ifa_addr->sa_family != AF_INET) continue;
            NSString *name = [NSString stringWithUTF8String:ifa->ifa_name ?: ""];
            if (![name isEqualToString:@"en0"]) continue;
            char host[INET_ADDRSTRLEN] = {0};
            struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;
            if (inet_ntop(AF_INET, &sa->sin_addr, host, sizeof(host))) result = [NSString stringWithUTF8String:host];
            break;
        }
        freeifaddrs(ifaddr);
    }
    return result;
}

- (NSString *)token {
    NSString *path = @"/var/mobile/Library/MyControl/token.txt";
    NSString *t = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return [t stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MyControl";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *title = [UILabel new];
    title.text = @"MyControl v0.4";
    title.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

    self.urlLabel = [UILabel new];
    self.urlLabel.numberOfLines = 0;
    self.urlLabel.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];

    self.tokenLabel = [UILabel new];
    self.tokenLabel.numberOfLines = 0;
    self.tokenLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.tokenLabel.textColor = UIColor.secondaryLabelColor;

    UIButton *open = [UIButton buttonWithType:UIButtonTypeSystem];
    [open setTitle:@"Open Control" forState:UIControlStateNormal];
    open.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    open.backgroundColor = UIColor.systemBlueColor;
    [open setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    open.layer.cornerRadius = 12;
    [open.heightAnchor constraintEqualToConstant:52].active = YES;
    [open addTarget:self action:@selector(openControl) forControlEvents:UIControlEventTouchUpInside];

    UIButton *copy = [UIButton buttonWithType:UIButtonTypeSystem];
    [copy setTitle:@"Copy LAN URL" forState:UIControlStateNormal];
    [copy.heightAnchor constraintEqualToConstant:44].active = YES;
    [copy addTarget:self action:@selector(copyURL) forControlEvents:UIControlEventTouchUpInside];

    UIButton *refresh = [UIButton buttonWithType:UIButtonTypeSystem];
    [refresh setTitle:@"Refresh Status" forState:UIControlStateNormal];
    [refresh.heightAnchor constraintEqualToConstant:44].active = YES;
    [refresh addTarget:self action:@selector(refreshStatus) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title,self.statusLabel,self.urlLabel,self.tokenLabel,open,copy,refresh]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24]
    ]];
    [self refreshStatus];
}

- (void)refreshStatus {
    NSString *ip = [self wifiIPv4];
    NSString *token = [self token];
    NSString *url = [NSString stringWithFormat:@"http://%@:9999/#%@", ip, token];
    self.statusLabel.text = token.length ? @"● Daemon configured" : @"○ Waiting for daemon token";
    self.statusLabel.textColor = token.length ? UIColor.systemGreenColor : UIColor.systemOrangeColor;
    self.urlLabel.text = [NSString stringWithFormat:@"LAN URL\n%@", url];
    self.tokenLabel.text = [NSString stringWithFormat:@"Pairing token\n%@", token.length ? token : @"(not ready)"];
}

- (void)openControl {
    MCWebViewController *vc = [MCWebViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)copyURL {
    NSString *url = [NSString stringWithFormat:@"http://%@:9999/#%@", [self wifiIPv4], [self token]];
    UIPasteboard.generalPasteboard.string = url;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Copied" message:@"LAN URL copied to clipboard." preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}
@end
