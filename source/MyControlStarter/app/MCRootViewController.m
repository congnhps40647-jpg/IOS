#import "MCRootViewController.h"

@interface MCRootViewController ()
@property(nonatomic, strong) UISegmentedControl *modeControl;
@property(nonatomic, strong) UIView *screenPage;
@property(nonatomic, strong) UIView *luaPage;
@property(nonatomic, strong) UIImageView *screenView;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UIButton *autoButton;
@property(nonatomic, strong) NSTimer *screenTimer;
@property(nonatomic) BOOL autoRefresh;
@property(nonatomic, strong) UITextField *scriptName;
@property(nonatomic, strong) UITextView *editor;
@property(nonatomic, strong) UITextView *consoleView;
@property(nonatomic, copy) NSString *pairingToken;
@end

@implementation MCRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MyControl";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.pairingToken = [self loadToken];
    self.autoRefresh = YES;

    self.modeControl = [[UISegmentedControl alloc] initWithItems:@[@"Screen", @"Lua"]];
    self.modeControl.selectedSegmentIndex = 0;
    [self.modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.modeControl;

    [self buildScreenPage];
    [self buildLuaPage];
    [self modeChanged:self.modeControl];
    [self refreshStatus];
    [self refreshScreen];

    self.screenTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(autoRefreshTick:) userInfo:nil repeats:YES];
}

- (void)dealloc {
    [self.screenTimer invalidate];
}

- (NSString *)loadToken {
    NSString *path = @"/var/mobile/Library/MyControl/token.txt";
    NSString *token = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return [token stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
}

- (void)buildScreenPage {
    self.screenPage = [UIView new];
    self.screenPage.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.screenPage];

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.text = @"Connecting to local daemon…";

    self.screenView = [UIImageView new];
    self.screenView.contentMode = UIViewContentModeScaleAspectFit;
    self.screenView.backgroundColor = UIColor.blackColor;
    self.screenView.layer.cornerRadius = 16.0;
    self.screenView.clipsToBounds = YES;

    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refreshScreen) forControlEvents:UIControlEventTouchUpInside];

    self.autoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.autoButton setTitle:@"Auto: ON" forState:UIControlStateNormal];
    [self.autoButton addTarget:self action:@selector(toggleAuto) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[refreshButton, self.autoButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.distribution = UIStackViewDistributionFillEqually;
    buttons.spacing = 12.0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.statusLabel, self.screenView, buttons]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.screenPage addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.screenPage.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.screenPage.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.screenPage.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.screenPage.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.topAnchor constraintEqualToAnchor:self.screenPage.topAnchor constant:12.0],
        [stack.leadingAnchor constraintEqualToAnchor:self.screenPage.leadingAnchor constant:16.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.screenPage.trailingAnchor constant:-16.0],
        [stack.bottomAnchor constraintEqualToAnchor:self.screenPage.safeAreaLayoutGuide.bottomAnchor constant:-12.0]
    ]];
}

- (void)buildLuaPage {
    self.luaPage = [UIView new];
    self.luaPage.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.luaPage];

    self.scriptName = [UITextField new];
    self.scriptName.borderStyle = UITextBorderStyleRoundedRect;
    self.scriptName.placeholder = @"script.lua";
    self.scriptName.text = @"hello.lua";
    self.scriptName.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.scriptName.autocorrectionType = UITextAutocorrectionTypeNo;

    self.editor = [UITextView new];
    self.editor.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.editor.layer.borderWidth = 1.0;
    self.editor.layer.borderColor = UIColor.separatorColor.CGColor;
    self.editor.layer.cornerRadius = 10.0;
    self.editor.text = @"print(\"MyControl native Lua\")\nprint(\"running on iPhone\")\n";

    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveScript) forControlEvents:UIControlEventTouchUpInside];

    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadScript) forControlEvents:UIControlEventTouchUpInside];

    UIButton *runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [runButton setTitle:@"▶ Run" forState:UIControlStateNormal];
    [runButton addTarget:self action:@selector(runScript) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[saveButton, loadButton, runButton]];
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.distribution = UIStackViewDistributionFillEqually;
    buttons.spacing = 8.0;

    UILabel *consoleTitle = [UILabel new];
    consoleTitle.text = @"Console";
    consoleTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];

    self.consoleView = [UITextView new];
    self.consoleView.editable = NO;
    self.consoleView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.consoleView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.consoleView.layer.cornerRadius = 10.0;
    self.consoleView.text = @"Ready.";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.scriptName, self.editor, buttons, consoleTitle, self.consoleView]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.luaPage addSubview:stack];

    [self.editor.heightAnchor constraintEqualToAnchor:self.luaPage.heightAnchor multiplier:0.48].active = YES;
    [self.consoleView.heightAnchor constraintGreaterThanOrEqualToConstant:120.0].active = YES;

    [NSLayoutConstraint activateConstraints:@[
        [self.luaPage.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.luaPage.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.luaPage.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.luaPage.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.topAnchor constraintEqualToAnchor:self.luaPage.topAnchor constant:12.0],
        [stack.leadingAnchor constraintEqualToAnchor:self.luaPage.leadingAnchor constant:12.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.luaPage.trailingAnchor constant:-12.0],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.luaPage.safeAreaLayoutGuide.bottomAnchor constant:-8.0]
    ]];
}

- (void)modeChanged:(UISegmentedControl *)sender {
    BOOL screenMode = sender.selectedSegmentIndex == 0;
    self.screenPage.hidden = !screenMode;
    self.luaPage.hidden = screenMode;
    [self.view endEditing:YES];
}

- (void)toggleAuto {
    self.autoRefresh = !self.autoRefresh;
    [self.autoButton setTitle:(self.autoRefresh ? @"Auto: ON" : @"Auto: OFF") forState:UIControlStateNormal];
}

- (void)autoRefreshTick:(NSTimer *)timer {
    (void)timer;
    if (self.autoRefresh && self.modeControl.selectedSegmentIndex == 0) [self refreshScreen];
}

- (NSMutableURLRequest *)requestForPath:(NSString *)path method:(NSString *)method body:(NSData *)body {
    NSURL *url = [NSURL URLWithString:[@"http://127.0.0.1:9999" stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    request.HTTPMethod = method;
    if (self.pairingToken.length) [request setValue:self.pairingToken forHTTPHeaderField:@"X-MyControl-Token"];
    if (body) {
        request.HTTPBody = body;
        [request setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }
    return request;
}

- (void)performJSONPath:(NSString *)path method:(NSString *)method body:(NSData *)body completion:(void (^)(NSDictionary *json, NSError *error))completion {
    NSMutableURLRequest *request = [self requestForPath:path method:method body:body];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        (void)response;
        NSDictionary *json = nil;
        if (data.length) json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(json ?: @{}, error); });
    }] resume];
}

- (void)refreshStatus {
    [self performJSONPath:@"/api/status" method:@"GET" body:nil completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            self.statusLabel.text = @"● daemon offline";
            self.statusLabel.textColor = UIColor.systemRedColor;
            return;
        }
        NSString *version = [json[@"version"] description] ?: @"?";
        BOOL capture = [json[@"screenCapture"] boolValue];
        self.statusLabel.text = [NSString stringWithFormat:@"● MyControl %@ · screen %@", version, capture ? @"ready" : @"unavailable"];
        self.statusLabel.textColor = UIColor.systemGreenColor;
    }];
}

- (void)refreshScreen {
    NSMutableURLRequest *request = [self requestForPath:@"/api/screenshot" method:@"GET" body:nil];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        UIImage *image = (!error && http.statusCode == 200 && data.length) ? [UIImage imageWithData:data] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) self.screenView.image = image;
            else if (error) self.statusLabel.text = [NSString stringWithFormat:@"Screenshot error: %@", error.localizedDescription];
        });
    }] resume];
}

- (NSString *)encodedScriptName {
    NSString *name = self.scriptName.text.length ? self.scriptName.text : @"script.lua";
    NSCharacterSet *allowed = NSCharacterSet.URLQueryAllowedCharacterSet;
    return [name stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"script.lua";
}

- (void)saveScript {
    NSData *body = [self.editor.text dataUsingEncoding:NSUTF8StringEncoding];
    NSString *path = [NSString stringWithFormat:@"/api/save?name=%@", [self encodedScriptName]];
    self.consoleView.text = @"Saving…";
    [self performJSONPath:path method:@"POST" body:body completion:^(NSDictionary *json, NSError *error) {
        if (error) self.consoleView.text = error.localizedDescription;
        else self.consoleView.text = [json[@"ok"] boolValue] ? @"Saved." : ([json[@"error"] description] ?: @"Save failed.");
    }];
}

- (void)loadScript {
    NSString *path = [NSString stringWithFormat:@"/api/load?name=%@", [self encodedScriptName]];
    self.consoleView.text = @"Loading…";
    [self performJSONPath:path method:@"GET" body:nil completion:^(NSDictionary *json, NSError *error) {
        if (error) self.consoleView.text = error.localizedDescription;
        else if ([json[@"ok"] boolValue]) {
            self.editor.text = [json[@"content"] description] ?: @"";
            self.consoleView.text = @"Loaded.";
        } else self.consoleView.text = [json[@"error"] description] ?: @"Load failed.";
    }];
}

- (void)runScript {
    NSData *body = [self.editor.text dataUsingEncoding:NSUTF8StringEncoding];
    self.consoleView.text = @"Running…";
    [self performJSONPath:@"/api/run" method:@"POST" body:body completion:^(NSDictionary *json, NSError *error) {
        if (error) {
            self.consoleView.text = error.localizedDescription;
            return;
        }
        NSString *output = [json[@"output"] description] ?: @"";
        NSString *exitCode = [json[@"exitCode"] description] ?: @"?";
        self.consoleView.text = [NSString stringWithFormat:@"exit=%@\n%@", exitCode, output];
    }];
}

@end
