//
//  XGALogViewController.m
//  xcode-github-app
//
//  Created by Edward on 5/8/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGALogViewController.h"
#import "BNCThreads.h"

#pragma mark XGALogRow

@implementation XGALogRow
@end

#pragma mark - XGALogViewController

@interface XGALogViewController () {
    NSMutableArray<XGALogRow*>*_logArray;
}
@property (weak)   IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;
@end

@implementation XGALogViewController

- (void) setLogArray:(NSMutableArray<XGALogRow*> *)logArray {
    @synchronized(self) {
        _logArray = logArray;
        self.arrayController.content = _logArray;
        self.representedObject = _logArray;
    }
}

- (NSArray<XGALogRow*>*) logArray {
    @synchronized(self) {
        return _logArray;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView setDoubleAction:@selector(doubleClickRow:)];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    BNCPerformBlockOnMainThreadAsync(^{ [self.tableView reloadData]; });
}

- (void) doubleClickRow:(id)sender {
    /*
    XGAServerStatus *status = self.arrayController.selectedObjects.firstObject;
    if (!status) return;
    */
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
