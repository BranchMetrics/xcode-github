//
//  ViewController.m
//  XcodeGitHub
//
//  Created by Edward on 3/12/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGAStatusViewController.h"
#import "XGXcodeBot.h"
#import "XGCommand.h"
#import "XGASettings.h"
#import "BNCThreads.h"
#import "BNCNetworkService.h"
#import "BNCLog.h"
#import <stdatomic.h>

#pragma mark NSAttributedString (APP)

NSData*_Nullable XGAImagePNGRepresentation(NSImage*image) {
//    NSAffineTransform *r = [[NSAffineTransform alloc] init];
//    [r rotateByDegrees:90.0];
//    NSDictionary*hints = @{
//        NSImageHintCTM: r,
//    };
    CGImageRef cgRef = [image CGImageForProposedRect:NULL context:nil hints:@{}];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    //  setSize:[image size]];   // if you want the same resolution
    newRep.size = NSMakeSize(image.size.width, image.size.height);
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:@{}];
    return pngData;
}

NSData*_Nullable XGAImageTIFFRepresentation(NSImage*image) {
    NSData*data = [image TIFFRepresentation];
    return data;
}

@interface NSAttributedString (XGA)
+ (NSAttributedString*) stringWithImage:(NSImage*)image rect:(NSRect)rect;
+ (NSMutableAttributedString*) stringWithStrings:(NSAttributedString*)string, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSAttributedString*) stringWithFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
@end

@implementation NSAttributedString (APP)

+ (NSAttributedString*) stringWithImage:(NSImage*)image rect:(NSRect)rect {
    NSData*imageData = XGAImageTIFFRepresentation(image);
    NSTextAttachment*a =
        [[NSTextAttachment alloc]
            initWithData:imageData
            ofType:(__bridge NSString*)kUTTypeTIFF];
    a.image = image;
    if (NSEqualRects(rect, NSZeroRect))
        rect = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    a.bounds = rect;
    NSAttributedString *string = [NSAttributedString attributedStringWithAttachment:a];
    return string;
}

+ (NSMutableAttributedString*) stringWithStrings:(NSAttributedString*)string, ... {
    va_list list;
    va_start(list, string);

    NSMutableAttributedString *result = [NSMutableAttributedString new];
    while (string) {
        if ([string isKindOfClass:NSString.class])
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:(NSString*)string]];
        else
        if ([string isKindOfClass:NSAttributedString.class])
            [result appendAttributedString:string];
        string = va_arg(list, NSAttributedString*);
    }

    va_end(list);
    return result;
}

+ (NSAttributedString*) stringWithFormat:(NSString *)format, ... {
    va_list argList;
    va_start(argList, format);
    NSString*s = [[NSString alloc] initWithFormat:format arguments:argList];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:s];
    va_end(argList);
    return as;
}
@end


#pragma mark - XGAServerStatus

@interface XGAServerStatus : NSObject
@property NSString *serverName;
@property NSString *botName;
@property NSImage  *statusImage;
@property NSString *statusSummary;
@property APFormattedString *statusDetail;
@end

@implementation XGAServerStatus
@end

#pragma mark - XGAStatusViewController

@interface XGAStatusViewController () {
    NSArray<XGAServerStatus*>*_serverStatusArray;
}
@property (strong) dispatch_queue_t asyncQueue;
@property (strong) dispatch_source_t statusTimer;
@property (assign) _Atomic(BOOL) statusIsInProgress;
@property (strong) NSArray<XGAServerStatus*> *serverStatusArray;
@property (weak)   IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;

// Display update
@property (weak)   IBOutlet NSProgressIndicator *updateProgessIndictor;
@property (strong) NSDate *lastUpdateDate;

@property (weak) IBOutlet NSTextField *statusTextField;
@end

@implementation XGAStatusViewController

+ (instancetype) loadController {
    XGAStatusViewController*controller = [[XGAStatusViewController alloc] init];
    BOOL loaded =
        [[NSBundle mainBundle]
            loadNibNamed:NSStringFromClass(self)
            owner:controller
            topLevelObjects:nil];
    return (loaded) ? controller : nil;
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
    [self.tableView setDoubleAction:@selector(doubleClickRow:)];
    self.window = self.view.window;
    XGAServerStatus *status = [XGAServerStatus new];
    status.statusSummary = @"< Refreshing >";
    self.serverStatusArray = @[ status ];
    [self startStatusUpdates];
}

- (void) doubleClickRow:(id)sender {
    /*
    XGAServerStatus *status = self.arrayController.selectedObjects.firstObject;
    if (!status) return;
    */
    NSInteger idx = self.tableView.selectedRow;
    if (idx < 0 || idx >= [self.arrayController.arrangedObjects count]) return;
    XGAServerStatus *status = [self.arrayController.arrangedObjects objectAtIndex:idx];
    if (![status isKindOfClass:XGAServerStatus.class]) return;
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = status.statusSummary;
    alert.informativeText = [status.statusDetail renderText];
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
    NSTimeInterval kStatusRefreshInterval = 30.0;

    NSTimeInterval elapsed = - [self.lastUpdateDate timeIntervalSinceNow];
    BNCPerformBlockOnMainThreadAsync(^{
        self.updateProgessIndictor.doubleValue = elapsed / kStatusRefreshInterval * 100.0;
    });
    if (elapsed < kStatusRefreshInterval && self.lastUpdateDate != nil)
        return;

    // Prevent double status getting:
    BOOL statusIsInProgress = atomic_exchange(&self->_statusIsInProgress, YES);
    if (statusIsInProgress) return;

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
    atomic_exchange(&self->_statusIsInProgress, NO);
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
                    [NSAttributedString stringWithImage:[NSImage imageNamed:@"RoundAlert"] rect:CGRectMake(0, -2, 12, 12)],
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
        status.statusSummary = @"Server Error";
        status.statusImage = [NSImage imageNamed:@"RoundAlert"];
        status.statusDetail = [APFormattedString plainText:error.localizedDescription];
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
    status.botName = ([XGXcodeBot gitHubPRNameFromString:botStatus.botName]) ?: botStatus.botName;
    status.statusSummary = botStatus.summaryString;

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
