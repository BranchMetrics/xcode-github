/**
 @file          XGAStatusViewController.m
 @package       xcode-github-app
 @brief         The view controller for the status window.

 @author        Edward Smith
 @date          March 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAStatusViewController.h"
#import "XGXcodeBot.h"
#import "XGCommand.h"
#import "XGASettings.h"
#import "XGAStatusPanel.h"
#import "APPArrowPanel.h"
#import "BNCThreads.h"
#import "BNCNetworkService.h"
#import "BNCLog.h"
#import "NSAttributedString+App.h"

#pragma mark - XGAServerStatus

@interface XGAServerStatus : NSObject
@property NSString *serverName;
@property NSString *botName;
@property NSImage  *statusImage;
@property (strong) APPFormattedString *statusSummary;
@property (strong) APPFormattedString *statusDetail;
@end

@implementation XGAServerStatus
@end

#pragma mark - XGAStatusViewController

@interface XGAStatusViewController () {
    NSArray<XGAServerStatus*>*_serverStatusArray;
}
@property (strong) dispatch_queue_t asyncQueue;
@property (strong) dispatch_source_t statusTimer;
@property (assign, nonatomic) _Atomic(BOOL) statusIsInProgress;
@property (strong) NSArray<XGAServerStatus*> *serverStatusArray;
@property (strong) XGAStatusPanel*statusPanel;
@property (weak)   IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;

// Display update
@property (weak)   IBOutlet NSProgressIndicator *updateProgessIndictor;
@property (strong) NSDate *lastUpdateDate;
@property (weak) IBOutlet NSTextField *statusTextField;
@end

@implementation XGAStatusViewController

+ (instancetype) new {
    XGAStatusViewController*controller = [[XGAStatusViewController alloc] init];
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(self)
        owner:controller
        topLevelObjects:nil];
    return controller;
}

- (void) setServerStatusArray:(NSArray<XGAServerStatus *> *)serverStatusArray {
    @synchronized(self) {
        _serverStatusArray = serverStatusArray;
        self.arrayController.content = _serverStatusArray;
    }
}

- (NSArray<XGAServerStatus*>*) serverStatusArray {
    @synchronized(self) {
        return _serverStatusArray;
    }
}

- (void)awakeFromNib {
    [super viewDidLoad];
    [self.tableView setDoubleAction:@selector(showInfo:)];
    self.window = self.view.window;
    XGAServerStatus *status = [XGAServerStatus new];
    status.statusSummary = [APPFormattedString boldText:@"< Refreshing >"];
    self.serverStatusArray = @[ status ];
    [self startStatusUpdates];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.statusPanel)
        [self showInfo:self];
}

#pragma mark - Selection Actions

- (IBAction) showInfo:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx < 0 || idx >= [self.arrayController.arrangedObjects count]) {
        [self.statusPanel dismiss];
        self.statusPanel = nil;
        return;
    }
    XGAServerStatus*status = [self.arrayController.arrangedObjects objectAtIndex:idx];
    if (![status isKindOfClass:XGAServerStatus.class]) return;

    NSRect r = [self.tableView rectOfRow:idx];
    r = [self.tableView convertRect:r toView:nil];
    r = [self.window convertRectToScreen:r];

    // Show the status panel:
    XGAStatusPanel*panel = [XGAStatusPanel loadPanel];
    NSFont*font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    panel.titleTextField.attributedStringValue =
        [[[[APPFormattedString builder]
            appendBold:@"%@", status.botName]
                build] renderAttributedStringWithFont:font];
    panel.statusImageView.image = status.statusImage;
    panel.statusTextField.attributedStringValue = [status.statusSummary renderAttributedStringWithFont:font];
    panel.detailTextField.attributedStringValue = [status.statusDetail renderAttributedStringWithFont:font];
    panel.arrowPoint = NSMakePoint(r.size.width/2.0+r.origin.x, r.origin.y);
    [panel show];
}

- (IBAction) monitorForNewPRs:(id)sender {
}

- (IBAction) delete:(id)sender {
}

- (BOOL) itemIsSelected {
    NSInteger idx = self.tableView.clickedRow;
    if (idx >= 0 && idx < [self.arrayController.arrangedObjects count]) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        return YES;
    }
    idx = self.tableView.selectedRow;
    if (idx >= 0 && idx < [self.arrayController.arrangedObjects count])
        return YES;
    return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(showInfo:) ||
        menuItem.action == @selector(monitorForNewPRs:) ||
        menuItem.action == @selector(delete:)) {
        return ([self itemIsSelected]);
    }
    return NO;
}

#pragma mark - Status Updates

- (void) startStatusUpdates {
    @synchronized (self) {
        if (self.statusTimer) return;

        if (!self.asyncQueue) {
            self.asyncQueue = dispatch_queue_create("io.branch.status_queue", DISPATCH_QUEUE_SERIAL);
        }
        dispatch_source_t localStatusTimer =
            dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.asyncQueue);
        self.statusTimer = localStatusTimer;
        if (!self.statusTimer) return;

        NSTimeInterval kUIRefreshInterval = 1.0;

        dispatch_time_t startTime =
            dispatch_time(DISPATCH_TIME_NOW, BNCNanoSecondsFromTimeInterval(kUIRefreshInterval));
        dispatch_source_set_timer(
            self.statusTimer,
            startTime,
            BNCNanoSecondsFromTimeInterval(kUIRefreshInterval),
            BNCNanoSecondsFromTimeInterval(kUIRefreshInterval / 10.0)
        );
        __weak __typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.statusTimer, ^ {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf)
                [strongSelf updateStatus];
            else
                dispatch_source_cancel(localStatusTimer);
        });
        dispatch_resume(self.statusTimer);
        dispatch_async(self.asyncQueue, ^{ [self updateStatus]; });
    }
}

- (void) stopStatusUpdates {
    @synchronized (self) {
        if (self.statusTimer) {
            dispatch_source_cancel(self.statusTimer);
            self.statusTimer = nil;
        }
    }
}

- (void) updateStatus {
    NSTimeInterval kStatusRefreshInterval = [XGASettings shared].refreshSeconds;

    NSTimeInterval elapsed = - [self.lastUpdateDate timeIntervalSinceNow];
    BNCPerformBlockOnMainThreadAsync(^{
        self.updateProgessIndictor.doubleValue = elapsed / kStatusRefreshInterval * 100.0;
    });
    if (elapsed < kStatusRefreshInterval && self.lastUpdateDate != nil)
        return;

    // Prevent double status getting:
    @synchronized(self) {
        if (self.statusIsInProgress) return;
        self.statusIsInProgress = YES;
    }

    BNCLogDebug(@"Start updateStatus.");
    BNCPerformBlockOnMainThreadAsync(^{ self.statusTextField.stringValue = @""; });
    NSMutableSet *statusServers = [NSMutableSet new];
    NSArray<XGAServerGitHubSyncTask*>* syncTasks = [XGASettings shared].serverGitHubSyncTasks;
    for (XGAServerGitHubSyncTask*task in syncTasks) {
        if (task.xcodeServerName.length == 0) continue;
        [[BNCNetworkService shared].anySSLCertHosts addObject:task.xcodeServerName];
        [self updateSyncBots:task];
        [statusServers addObject:task.xcodeServerName];
    }
    for (NSString*serverName in statusServers) {
        [self updateXcodeServerStatus:serverName];
    }
    BNCLogDebug(@"End updateStatus.");

    self.lastUpdateDate = [NSDate date];
    BNCPerformBlockOnMainThreadAsync(^ { self.updateProgessIndictor.doubleValue = 0.0; });

    // Release status lock:
    self.statusIsInProgress = NO;
}

- (void) updateSyncBots:(XGAServerGitHubSyncTask*)syncTask {
    NSError*error = nil;
    if (syncTask.xcodeServerName.length &&
        syncTask.gitHubRepo.length &&
        syncTask.templateBotName.length) {
        XGCommandOptions*options = [XGCommandOptions new];
        options.xcodeServerName = syncTask.xcodeServerName;
        options.templateBotName = syncTask.templateBotName;
        options.githubAuthToken = syncTask.gitHubToken;
        options.dryRun = YES;
        error = XGUpdateXcodeBotsWithGitHub(options);
        if (error) {
            NSMutableAttributedString*message =
                [NSAttributedString stringWithStrings:
                    [NSAttributedString stringWithImage:
                        [NSImage imageNamed:@"RoundAlert"] rect:CGRectMake(0, -2, 12, 12)],
                    [NSAttributedString stringWithFormat:@" %@:%@    —    %@",
                        options.xcodeServerName, options.templateBotName, error.localizedDescription],
                    nil];
            BNCPerformBlockOnMainThreadAsync(^{
                self.statusTextField.attributedStringValue = message;
            });
        }
    }
}

- (void) updateXcodeServerStatus:(NSString*)serverName {
    NSError*error = nil;
    NSMutableArray *statusArray = [NSMutableArray new];
    NSDictionary<NSString*, XGXcodeBot*>* bots = [XGXcodeBot botsForServer:serverName error:&error];
    if (error) {
        XGAServerStatus *status = [XGAServerStatus new];
        status.serverName = serverName;
        status.statusSummary = [APPFormattedString boldText:@"Server Error"];
        status.statusImage = [NSImage imageNamed:@"RoundAlert"];
        status.statusDetail = [APPFormattedString plainText:error.localizedDescription];
        [statusArray addObject:status];
    } else {
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            XGXcodeBotStatus*botStatus = [bot status];
            XGAServerStatus*status = [self statusWithBotStatus:botStatus];
            if (status) [statusArray addObject:status];
        }
    }
    if (statusArray.count == 0) {
        XGAServerStatus *status = [XGAServerStatus new];
        status.statusSummary = [APPFormattedString boldText:@"< No Xcode servers yet >"];
    }
    BNCPerformBlockOnMainThreadAsync(^{
        self.serverStatusArray = statusArray;
    });
}

- (XGAServerStatus*) statusWithBotStatus:(XGXcodeBotStatus*)botStatus {
    if (botStatus == nil) return nil;
    XGAServerStatus *status = [XGAServerStatus new];
    status.serverName = botStatus.serverName;
    status.botName = ([XGXcodeBot gitHubPRNameFromString:botStatus.botName]) ?: botStatus.botName;
    status.statusSummary = [APPFormattedString boldText:botStatus.summaryString];

    NSString *result = [botStatus.result lowercaseString];
    if ([botStatus.currentStep containsString:@"completed"]) {

        NSString*imageName = @"RoundRed";
        if ([result containsString:@"succeeded"])
            imageName = @"RoundGreen";
        else
        if ([result containsString:@"unknown"])
            imageName = @"RoundAlert";
        else
        if ([result containsString:@"warning"])
            imageName = @"RoundYellow";
        else
        if ([result containsString:@"unknown"])
            imageName = @"RoundAlert";

        status.statusImage = [NSImage imageNamed:imageName];

    } else
    if ([botStatus.currentStep containsString:@"pending"]) {
        status.statusImage = [NSImage imageNamed:@"RoundGrey"];
    } else
        status.statusImage = [NSImage imageNamed:@"RoundBlue"];

    status.statusDetail = botStatus.formattedDetailString;
    return status;
}

@end
