//
//  main.m
//  XcodeGitHub
//
//  Created by Edward on 3/12/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XGALogViewController.h"

#pragma mark Log Function

NSMutableArray<XGALogRow*>*logMessages = nil;

void XGALogFunction(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message) {
    XGALogRow*row = [[XGALogRow alloc] init];
    row.date = timestamp;
    row.logLevel = level;
    row.logMessage = message;
    [logMessages addObject:row];
}

#pragma mark - main

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        logMessages = [[NSMutableArray alloc] init];
        BNCLogSetDisplayLevel(BNCLogLevelAll);
        BNCLog(@"%@ version %@(%@).",
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
        );
        return NSApplicationMain(argc, argv);
    }
}
