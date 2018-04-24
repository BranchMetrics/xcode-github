//
//  ViewController.m
//  XcodeGitHub
//
//  Created by Edward on 3/12/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGAStatusViewController.h"
#import "BNCUtilities.h"
#import "XGXcodeBot.h"
#import "BNCNetworkService.h"

#pragma mark XGAServerStatus

@interface XGAServerStatus : NSObject
@property NSString *serverName;
@property NSString *pullRequestName;
@property NSString *statusSummary;
@property NSString *statusDetail;
@end

@implementation XGAServerStatus
@end

#pragma mark - XGAStatusViewController

@interface XGAStatusViewController () {
    NSArray<XGAServerStatus*>*_serverStatusArray;
}
@property (strong) dispatch_queue_t asyncQueue;
@property (strong) dispatch_source_t statusTimer;
@property (strong) NSArray<XGAServerStatus*> *serverStatusArray;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak)   IBOutlet NSTableView *tableView;
@end

@implementation XGAStatusViewController

- (void) dealloc {
    @synchronized(self) {
        [self stopStatusUpdates];
    }
}

- (void) setServerStatusArray:(NSArray<XGAServerStatus *> *)serverStatusArray {
    @synchronized(self) {
        _serverStatusArray = serverStatusArray;
        self.arrayController.content = _serverStatusArray;
        self.representedObject = _serverStatusArray;
    }
}

- (NSArray<XGAServerStatus*>*) serverStatusArray {
    @synchronized(self) {
        return _serverStatusArray;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setDoubleAction:@selector(doubleClickRow:)];

    XGAServerStatus *status = [XGAServerStatus new];
    status.statusSummary = @"< Refreshing >";
    self.serverStatusArray = @[ status ];
    [self startStatusUpdates];

/* eDebug
    XGAServerStatus *status = [XGAServerStatus new];
    status.serverName = @"esmith.local";
    status.pullRequestName = @"Branch:ios-branch-deep-linking #811 Skype Sharing DEVEX-278";
    status.statusSummary = @"Success";
    status.statusDetail = @"All 277 tests completed successfully.";
    self.serverStatusArray = @[ status ];
*/
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    BNCPerformBlockOnMainThreadAsync(^{ [self.tableView reloadData]; });
}

- (void) doubleClickRow:(id)sender {
    XGAServerStatus *status = self.arrayController.selectedObjects.firstObject;
    if (!status) return;

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = status.statusSummary;
    alert.informativeText = status.statusDetail;
    alert.alertStyle = NSAlertStyleWarning;
    [alert runModal];
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

        NSTimeInterval kStatusRefreshInterval = 30.0;

        dispatch_time_t startTime =
            dispatch_time(DISPATCH_TIME_NOW, BNCNanoSecondsFromTimeInterval(kStatusRefreshInterval));
        dispatch_source_set_timer(
            self.statusTimer,
            startTime,
            BNCNanoSecondsFromTimeInterval(kStatusRefreshInterval),
            BNCNanoSecondsFromTimeInterval(kStatusRefreshInterval / 10.0)
        );
        __weak __typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.statusTimer, ^ {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf updateStatus];
            } else {
                dispatch_source_cancel(localStatusTimer);
            }
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
    NSError*error = nil;
    NSString*serverName = @"esmith.local";
    [[BNCNetworkService shared].anySSLCertHosts addObject:serverName];
    NSMutableArray *statusArray = [NSMutableArray new];
    NSDictionary<NSString*, XGXcodeBot*>* bots = [XGXcodeBot botsForServer:serverName error:&error];
    if (error) {
        XGAServerStatus *status = [XGAServerStatus new];
        status.serverName = serverName;
        status.statusSummary = @"Server Error";
        status.statusDetail = error.localizedDescription;
        [statusArray addObject:status];
    } else {
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            XGXcodeBotStatus*botStatus = [bot status];
            XGAServerStatus* status = [self statusWithBotStatus:botStatus];
            if (status) [statusArray addObject:status];
        }
    }
    if (statusArray.count == 0) {
        XGAServerStatus *status = [XGAServerStatus new];
        status.statusSummary = @"< No Xcode servers yet >";
    }
    BNCPerformBlockOnMainThreadAsync(^{
        self.serverStatusArray = statusArray;
    });
}

- (XGAServerStatus*) statusWithBotStatus:(XGXcodeBotStatus*)botStatus {
    if (botStatus == nil) return nil;
    XGAServerStatus *status = [XGAServerStatus new];
    status.serverName = botStatus.serverName;
    status.pullRequestName = botStatus.botName;
    if ([botStatus.currentStep isEqualToString:@"completed"]) {
        status.statusSummary = botStatus.result;
    } else {
        status.statusSummary = botStatus.currentStep;
    }
    status.statusSummary =
        [[status.statusSummary
            stringByReplacingOccurrencesOfString:@"-" withString:@" "]
            capitalizedString];
    status.statusDetail = @"No detail yet!";
    return status;
}

@end
