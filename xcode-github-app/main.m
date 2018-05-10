//
//  main.m
//  XcodeGitHub
//
//  Created by Edward on 3/12/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XGALogViewController.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [XGALogViewController startLog];
        return NSApplicationMain(argc, argv);
    }
}
