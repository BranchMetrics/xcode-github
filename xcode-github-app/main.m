/**
 @file          main.m
 @package       xcode-github-app
 @brief         The main entry point for the xcode-github-app.

 @author        Edward Smith
 @date          March 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import "XGALogViewController.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [XGALogViewController startLog];
        return NSApplicationMain(argc, argv);
    }
}
