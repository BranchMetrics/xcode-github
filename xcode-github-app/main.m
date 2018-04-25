//
//  main.m
//  XcodeGitHub
//
//  Created by Edward on 3/12/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BNCLog.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        BNCLogSetDisplayLevel(BNCLogLevelAll);
        BNCLog(@"%@ version %@(%@).",
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
        );
        return NSApplicationMain(argc, argv);
    }
}
