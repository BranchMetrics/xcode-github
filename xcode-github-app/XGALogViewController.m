//
//  XGALogViewController.m
//  xcode-github-app
//
//  Created by Edward on 5/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGALogViewController.h"
#import "BNCLog.h"
#import "BNCThreads.h"

NSString*const XGALogUpdateNotification = @"XGALogUpdatedNotification";

#pragma mark XGALogRow

@interface XGALogRow : NSObject
@property (nonatomic, strong) NSDate*date;
@property (nonatomic, assign) BNCLogLevel logLevel;
@property (nonatomic, strong) NSImage*logLevelImage;
@property (nonatomic, strong) NSString*logMessage;
@end

@implementation XGALogRow
@end

#pragma mark - XGALogViewController

@interface XGALogViewController ()
+ (NSMutableArray<XGALogRow*>*) logArray;
+ (NSImage*) imageForLogLevel:(BNCLogLevel)level;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak)   IBOutlet NSTableView*tableView;
@end

#pragma mark - Log Function

void XGALogFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message) {
    XGALogRow*row = [[XGALogRow alloc] init];
    row.date = timestamp;
    row.logLevel = level;
    row.logLevelImage = [XGALogViewController imageForLogLevel:level];
    row.logMessage = message;
    [[XGALogViewController logArray] addObject:row];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:XGALogUpdateNotification
        object:XGALogViewController.class];
}

#pragma mark - XGALogViewController

@implementation XGALogViewController

+ (void) startLog {
    BNCLogSetOutputFunction(XGALogFunction);
    BNCLogSetDisplayLevel(BNCLogLevelWarning);
    BNCLog(@"%@ version %@(%@).",
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
    );
}

+ (NSMutableArray<XGALogRow*>*) logArray {
    static NSMutableArray*logArray = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        logArray = [[NSMutableArray alloc] init];
    });
    return logArray;
}

+ (instancetype) loadController {
    XGALogViewController*controller = [[XGALogViewController alloc] init];
    BOOL loaded =
        [[NSBundle mainBundle]
            loadNibNamed:NSStringFromClass(self)
            owner:controller
            topLevelObjects:nil];
    return (loaded) ? controller : nil;
}

+ (NSImage*) imageForLogLevel:(BNCLogLevel)level {
    /*
    typedef NS_ENUM(NSInteger, BNCLogLevel) {
        BNCLogLevelAll = 0,
        BNCLogLevelDebugSDK = BNCLogLevelAll,
        BNCLogLevelBreakPoint,
        BNCLogLevelDebug,
        BNCLogLevelWarning,
        BNCLogLevelError,
        BNCLogLevelAssert,
        BNCLogLevelLog,
        BNCLogLevelNone,
        BNCLogLevelMax
    };
    */
    @synchronized(self) {
        static NSArray*logIcons = nil;
        if (!logIcons) {
            logIcons = @[
                [NSImage imageNamed:@"RoundDebug"],  // 0 = BNCLogLevelDebugSDK
                [NSImage imageNamed:@"RoundDebug"],
                [NSImage imageNamed:@"RoundDebug"],
                [NSImage imageNamed:@"RoundYellow"], // 3 = BNCLogLevelWarning
                [NSImage imageNamed:@"RoundRed"],
                [NSImage imageNamed:@"RoundAlert"],  // 5 = Assert
                [NSImage imageNamed:@"RoundBlue"],
            ];
        }
        return logIcons[level];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.tableView setDoubleAction:@selector(doubleClickRow:)];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(logUpdatedNotification:)
        name:XGALogUpdateNotification
        object:nil];
    self.arrayController.content = self.class.logArray;
}

- (void)logUpdatedNotification:(NSNotification*)notification {
    BNCPerformBlockOnMainThreadAsync(^{
        NSRect visibleRect = self.tableView.enclosingScrollView.documentVisibleRect;
        NSRect contentRect = self.tableView.enclosingScrollView.documentView.frame;
        [self.arrayController rearrangeObjects];
        if ((visibleRect.origin.y + visibleRect.size.height) >=
            (contentRect.origin.y + contentRect.size.height)) {
                NSInteger rowIdx = [self.arrayController.arrangedObjects count] - 1;
                if (rowIdx >= 0) [self.tableView scrollRowToVisible:rowIdx];
        }
    });
}

- (void) doubleClickRow:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx < 0 || idx >= [self.arrayController.arrangedObjects count]) return;
    XGALogRow *row = [self.arrayController.arrangedObjects objectAtIndex:idx];
    if (![row isKindOfClass:XGALogRow.class]) return;

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.informativeText = row.logMessage;
    alert.alertStyle = NSAlertStyleWarning;
    [alert runModal];
}

@end
