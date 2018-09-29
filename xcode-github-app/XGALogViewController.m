/**
 @file          XGALogViewController.m
 @package       xcode-github-app
 @brief         The log window view controller.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGALogViewController.h"
#import "BNCLog.h"
#import "BNCThreads.h"
#import "APPFormattedString.h"
#import "XGASettings.h"
#import "XGAStatusPopover.h"

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
@property (strong) NSDateFormatter*dateFormatter;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak)   IBOutlet NSTableView*tableView;
@property (strong) XGAStatusPopover*statusPopover;
@end

#pragma mark - Log Function

void XGALogFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message) {
    XGALogRow*row = [[XGALogRow alloc] init];
    row.date = timestamp;
    row.logLevel = level;
    row.logLevelImage = [XGALogViewController imageForLogLevel:level];
    if (YES) {
        // Make the message pretty:
        NSRange range = [message rangeOfString:@": "];
        if (range.location != NSNotFound && range.location+2 < message.length)
            message = [message substringFromIndex:range.location+2];
    }
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

+ (instancetype) new {
    XGALogViewController*controller = [[XGALogViewController alloc] init];
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(self)
        owner:controller
        topLevelObjects:nil];
    controller.window.excludedFromWindowsMenu = YES;
    [controller startObservers];
    return controller;
}

+ (NSString*) stringForLogLevel:(BNCLogLevel)level {
    NSArray<NSString*>*names = @[
        @"Debug SDK",
        @"Break Point",
        @"Debug",
        @"Warning",
        @"Error",
        @"Assert",
        @"Information"
    ];
    return names[level];
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

- (void) startObservers {
    if (!self.dateFormatter) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }

    [self.tableView setDoubleAction:@selector(showstatusPopoverAction:)];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(logUpdatedNotification:)
        name:XGALogUpdateNotification
        object:nil];
    self.arrayController.content = self.class.logArray;
    [[XGASettings shared]
        addObserver:self
        forKeyPath:@"showDebugMessages"
        options:0
        context:NULL];
}

- (void) dealloc {
    [self.statusPopover close];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[XGASettings shared] removeObserver:self forKeyPath:@"showDebugMessages"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject:(id)object
        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
        context:(void *)context {
    if ([XGASettings shared].showDebugMessages) {
        self.arrayController.filterPredicate = nil;
    } else {
        self.arrayController.filterPredicate =
            [NSPredicate predicateWithFormat:@"logLevel > 2"];
    }
}

- (void)logUpdatedNotification:(NSNotification*)notification {
    BNCPerformBlockOnMainThreadAsync(^{
        NSRect visibleRect = self.tableView.enclosingScrollView.documentVisibleRect;
        NSRect contentRect = self.tableView.enclosingScrollView.documentView.frame;
        // NSLog(@"Logging v: %@ c: %@.", NSStringFromRect(visibleRect), NSStringFromRect(contentRect));
        [self.arrayController rearrangeObjects];
        if ((visibleRect.origin.y + visibleRect.size.height) >= contentRect.size.height) {
                NSInteger rowIdx = self.tableView.numberOfRows - 1;
                if (rowIdx >= 0) {
                    // NSLog(@"Scroll to bottom: %ld.", rowIdx);
                    [self.tableView scrollRowToVisible:rowIdx];
                }
        }
    });
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.statusPopover)
        [self showstatusPopoverAction:self];
}

- (void) showstatusPopoverAction:(id)sender {
    NSInteger idx = self.tableView.selectedRow;
    if (idx < 0 || idx >= [self.arrayController.arrangedObjects count]) {
        [self.statusPopover close];
        return;
    }
    XGALogRow *row = [self.arrayController.arrangedObjects objectAtIndex:idx];
    if (![row isKindOfClass:XGALogRow.class]) return;

    APPFormattedString*status =
        [[[[APPFormattedString new]
            boldText:@"%@", [XGALogViewController stringForLogLevel:row.logLevel]]
            plainText:@"     "]
            italicText:@"%@", [self.dateFormatter stringFromDate:row.date]];

    if (!self.statusPopover) self.statusPopover = [[XGAStatusPopover alloc] init];
    NSFont*font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    self.statusPopover.statusImageView.image = [XGALogViewController imageForLogLevel:row.logLevel];
    self.statusPopover.statusTextField.attributedStringValue = [status renderAttributedStringWithFont:font];
    self.statusPopover.detailTextField.stringValue = row.logMessage;

    NSRect r = [self.tableView rectOfRow:idx];
    [self.statusPopover showRelativeToRect:r ofView:self.tableView preferredEdge:NSRectEdgeMaxY];
}

@end
