/**
 @file          APPFormattedString.Test.m
 @package       xcode-github-app
 @brief         Tests for APPFormattedString.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "APPFormattedString.h"

@interface APPFormattedStringTest : BNCTestCase
@end

@implementation APPFormattedStringTest

- (APPFormattedString*) createTestString {
    APPFormattedString *string =
        [[[[[APPFormattedString builder]
            appendPlain:@"Ten: %ld.", (long) 10]
            appendBold:@" Bold text."]
            appendPlain:@" Normal text."]
                build];
    return string;
}

- (void) testText {
    APPFormattedString *string = [self createTestString];
    NSString* result = [string renderText];
    XCTAssertEqualObjects(result, @"Ten: 10. Bold text. Normal text.");
}

- (void) testMarkDown {
    APPFormattedString *string = [self createTestString];
    NSString* result = [string renderMarkDown];
    XCTAssertEqualObjects(result, @"Ten: 10.** Bold text.** Normal text.");
}

@end
