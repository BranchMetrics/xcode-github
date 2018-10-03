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
#import "XGAStatusPopover.h"
#import "BNCThreads.h"
#import "BNCNetworkService.h"
#import "BNCLog.h"
#import "NSAttributedString+App.h"
#import "XGAStatusViewItem.h"

#pragma mark XGAStatusViewController

@interface XGAStatusViewController () <NSTableViewDelegate, NSPopoverDelegate>
@property (strong) dispatch_queue_t asyncQueue;
@property (strong) dispatch_source_t statusTimer;
@property (assign, nonatomic) _Atomic(BOOL) statusIsInProgress;
@property (strong) XGAStatusPopover*statusPopover;
@property (weak)   IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (assign) BOOL awake;

// Display update
@property (weak)   IBOutlet NSProgressIndicator *updateProgessIndictor;
@property (strong) NSDate *lastUpdateDate;
@property (weak) IBOutlet NSTextField *statusTextField;
@end

#pragma mark - XGAStatusViewController

@implementation XGAStatusViewController

+ (instancetype) new {
    XGAStatusViewController*controller = [[XGAStatusViewController alloc] init];
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(self)
        owner:controller
        topLevelObjects:nil];
    controller.window.excludedFromWindowsMenu = YES;
    return controller;
}

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = YES;
        [self.tableView setDoubleAction:@selector(showInfo:)];
        self.window = self.view.window;
        XGAStatusViewItem *status = [XGAStatusViewItem new];
        status.statusImage = [NSImage imageNamed:@"RoundBlue"];
        status.statusSummary = [APFormattedString boldText:@"< Refreshing >"];
        self.arrayController.content = @[ status ];
        [self startStatusUpdates];
        self.tableView.delegate = self;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.statusPopover.popover.isShown) [self showInfo:self.tableView];
}

- (XGAStatusViewItem*) selectedTableItem {
    NSInteger idx = self.tableView.clickedRow;
    if (idx >= 0 && idx < [self.arrayController.arrangedObjects count]) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        return [self.arrayController.arrangedObjects objectAtIndex:idx];
    }
    idx = self.tableView.selectedRow;
    if (idx >= 0 && idx < [self.arrayController.arrangedObjects count])
        return [self.arrayController.arrangedObjects objectAtIndex:idx];;
    return nil;
}

#pragma mark - Actions

- (IBAction) showInfo:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx < 0 || idx >= [self.arrayController.arrangedObjects count]) {
        [self.statusPopover close];
        return;
    }
    XGAStatusViewItem*status = [self.arrayController.arrangedObjects objectAtIndex:idx];
    if (![status isKindOfClass:XGAStatusViewItem.class]) return;

    // Show the status panel:
    if (!self.statusPopover) {
        self.statusPopover = [[XGAStatusPopover alloc] init];
    }
    NSFont*font = [NSFont systemFontOfSize:[NSFont systemFontSize]];

    // Title
    self.statusPopover.titleTextField.stringValue = @"";

    // Status
    self.statusPopover.statusImageView.image = status.statusImage;
    self.statusPopover.statusTextField.attributedStringValue =
        [status.statusSummary renderAttributedStringWithFont:font];

    // Detail
    __auto_type detail =
        [APFormattedString boldText:@"%@\n%@\n\n", status.repository, status.branchOrPRName];
    [detail append:status.statusDetail];
    [detail italicText:@"\n\nBot: %@", status.botName.length ? status.botName : @"Unknown"];
    self.statusPopover.detailTextField.attributedStringValue =
        [detail renderAttributedStringWithFont:font];

    NSRect r = [self.tableView rectOfRow:idx];
    if ([sender isKindOfClass:NSTableView.class]) {
        NSPoint p = self.window.mouseLocationOutsideOfEventStream;
        r.size.width = 20.0;
        r.origin.x = p.x - 10.0;
    }
    [self.statusPopover showRelativeToRect:r ofView:self.tableView preferredEdge:NSRectEdgeMaxY];
}

- (IBAction) monitorRepo:(id)sender {
    XGAStatusViewItem*item = [self selectedTableItem];
    if (!item || !item.hasGitHubRepo || [item.botIsFromTemplate boolValue])
        return;
    if (item.isXGAMonitored) {

        __auto_type tasks = [XGASettings shared].gitHubSyncTasks;
        XGAGitHubSyncTask*taskToRemove = nil;
        for (XGAGitHubSyncTask*task in tasks) {
            if (item.server.length && item.bot.name.length &&
                [task.xcodeServer isEqualToString:item.server] &&
                [task.botNameForTemplate isEqualToString:item.bot.name]) {
                taskToRemove = task;
                break;
            }
        }
        if (taskToRemove) [tasks removeObject:taskToRemove];

    } else {

        __auto_type task = [XGAGitHubSyncTask new];
        task.xcodeServer = item.bot.serverName;
        task.botNameForTemplate = item.botName;
        [[XGASettings shared].gitHubSyncTasks addObject:task];

    }
    [[XGASettings shared] save];
    [self reload:self];
}

- (IBAction) delete:(id)sender {
    XGAStatusViewItem*status = [self selectedTableItem];
    if (!status) return;
    __auto_type alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"Delete '%@'?", status.botName];
    alert.informativeText =
        [NSString stringWithFormat:@"Are you sure you want to delete the bot '%@'?", status.botName];
    alert.alertStyle = NSAlertStyleInformational;
    [[alert addButtonWithTitle:@"Delete"] setTag:NSModalResponseOK];
    [[alert addButtonWithTitle:@"Cancel"] setTag:NSModalResponseCancel];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            __auto_type*bot = [[XGXcodeBot alloc] initWithServerName:status.server botID:status.bot.botID];
            NSError*error = [bot removeFromServer];
            if (error) {
                __auto_type ea = [[NSAlert alloc] init];
                ea.messageText = [NSString stringWithFormat:@"Error deleting '%@'.", status.botName];
                ea.informativeText = error.localizedDescription;
                ea.alertStyle = NSAlertStyleCritical;
                [ea beginSheetModalForWindow:self.window completionHandler:nil];
            } else {
                [self updateStatusNow];
            }
        }
    }];
}

- (IBAction) showInXcode:(id)sender {
    XGAStatusViewItem*status = [self selectedTableItem];
    if (!status) return;
    NSString*string = nil;
    if (status.botStatus.integrationID) {
        string = [NSString stringWithFormat:@"xcbot://%@/botID/%@/integrationID/%@",
            status.server, status.bot.botID, status.botStatus.integrationID];
    } else {
        string = [NSString stringWithFormat:@"xcbot://%@/botID/%@",
            status.server, status.bot.botID];
    }
    NSURL*URL = [NSURL URLWithString:string];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

- (IBAction) showInBrowser:(id)sender {
    XGAStatusViewItem*status = [self selectedTableItem];
    if (!status) return;
    NSString*string =
        [NSString stringWithFormat:@"https://%@/xcode/bots/%@",
            status.server, status.botStatus.botTinyID];
    NSURL*URL = [NSURL URLWithString:string];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

- (IBAction) downloadAssets:(id)sender {
    XGAStatusViewItem*status = [self selectedTableItem];
    if (!status) return;
    NSString*string =
        [NSString stringWithFormat:@"https://%@/xcode/internal/api/integrations/%@/assets",
            status.server, status.botStatus.integrationID];
    NSURL*URL = [NSURL URLWithString:string];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

- (IBAction)reload:(id)sender {
    [self updateStatusNow];
}

- (IBAction)smartSort:(id)sender {
    // Sort by repository, template bot name, botIsFromTemplate first, branchOrPRName
    self.tableView.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"server"
            ascending:YES selector:@selector(caseInsensitiveCompare:)],
        [NSSortDescriptor sortDescriptorWithKey:@"repository"
            ascending:YES selector:@selector(caseInsensitiveCompare:)],
        [NSSortDescriptor sortDescriptorWithKey:@"templateBotName"
            ascending:YES selector:@selector(caseInsensitiveCompare:)],
        [NSSortDescriptor sortDescriptorWithKey:@"botIsFromTemplate"
            ascending:YES selector:@selector(compare:)],
        [NSSortDescriptor sortDescriptorWithKey:@"branchOrPRName"
            ascending:YES selector:@selector(caseInsensitiveCompare:)],
    ];
/*
    self.tableView.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"repository"
            ascending:YES selector:@selector(caseInsensitiveCompare:)],
        [NSSortDescriptor sortDescriptorWithKey:@"branchOrPRName"
            ascending:YES selector:@selector(compare:)],
    ];
*/
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(reload:))
        return YES;
    if (menuItem.action == @selector(smartSort:)) {
        menuItem.state = (self.tableView.sortDescriptors.count == 5);
        return YES;
    }
    if (menuItem.action == @selector(monitorRepo:)) {
        menuItem.state = 0;
        XGAStatusViewItem*item = [self selectedTableItem];
        if (item.hasGitHubRepo && ![item.botIsFromTemplate boolValue]) {
            menuItem.state = item.isXGAMonitored;
            return YES;
        }
        return NO;
    }
    SEL contextMenuItems[] = {
        @selector(showInfo:),
        @selector(monitorRepo:),
        @selector(delete:),
        @selector(showInXcode:),
        @selector(showInBrowser:),
        @selector(downloadAssets:),
        NULL
    };
    SEL*item = contextMenuItems;
    while (*item && *item != menuItem.action) ++item;
    if (*item) return ([self selectedTableItem] != nil);
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
            self.lastUpdateDate = nil;
        }
    }
}

- (void) updateStatusNow {
    @synchronized (self) {
        self.lastUpdateDate = nil;
        [self updateStatus];
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
    NSMutableSet<NSString*>*statusServers = [NSMutableSet new];
    for (XGAServer*server in XGASettings.shared.servers) {
        [statusServers addObject:server.server];
    }
    NSArray<XGAGitHubSyncTask*>* syncTasks = XGASettings.shared.gitHubSyncTasks;
    for (XGAGitHubSyncTask*task in syncTasks) {
        if (task.xcodeServer.length == 0) continue;
        [self updateSyncBots:task];
        [statusServers addObject:task.xcodeServer];
    }
    for (NSString*server in statusServers) {
        [self updateXcodeServerStatus:server];
    }
    if (syncTasks.count == 0 && statusServers.count == 0) {
        [self updateXcodeServerStatus:nil];
    }
    BNCLogDebug(@"End updateStatus.");

    self.lastUpdateDate = [NSDate date];
    BNCPerformBlockOnMainThreadAsync(^ { self.updateProgessIndictor.doubleValue = 0.0; });

    // Release status lock:
    self.statusIsInProgress = NO;
}

- (void) updateSyncBots:(XGAGitHubSyncTask*)syncTask {
    NSError*error = nil;
    if (syncTask.xcodeServer.length &&
        syncTask.botNameForTemplate.length) {
        XGCommandOptions*options = [XGCommandOptions new];
        options.xcodeServerName = syncTask.xcodeServer;
        options.templateBotName = syncTask.botNameForTemplate;
        options.githubAuthToken = XGASettings.shared.gitHubToken;
        options.dryRun = XGASettings.shared.dryRun;
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

- (void) updateXcodeServerStatus:(NSString*)server {
    NSError*error = nil;
    NSMutableArray *statusArray = [NSMutableArray new];
    if (server.length > 0) {
        NSDictionary<NSString*, XGXcodeBot*>* bots = [XGXcodeBot botsForServer:server error:&error];
        if (error) {
            XGAStatusViewItem *status = [XGAStatusViewItem new];
            status.server = server;
            status.statusSummary = [APFormattedString boldText:@"Server Error"];
            status.statusImage = [NSImage imageNamed:@"RoundAlert"];
            status.statusDetail = [APFormattedString plainText:@"%@", error.localizedDescription];
            [statusArray addObject:status];
        } else {
            for (XGXcodeBot *bot in bots.objectEnumerator) {
                XGXcodeBotStatus*botStatus = [bot status];
                __auto_type item = [XGAStatusViewItem itemWithBot:bot status:botStatus];
                if (item) [statusArray addObject:item];
            }
        }
    }
    if (statusArray.count == 0) {
        XGAStatusViewItem *status = [XGAStatusViewItem new];
        status.statusImage = [NSImage imageNamed:@"RoundBlue"];
        status.statusSummary = [APFormattedString boldText:@"< No Xcode servers added yet >"];
        [statusArray addObject:status];
    }
    BNCPerformBlockOnMainThreadAsync(^{
        self.arrayController.content = statusArray;
    });
}

@end
