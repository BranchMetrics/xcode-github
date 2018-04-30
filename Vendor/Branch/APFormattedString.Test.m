/**
 @file          APFormattedString.Test.m
 @package       xcode-github-app
 @brief         Tests for APFormattedString.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "APFormattedString.h"

@interface APFormattedStringTest : BNCTestCase
@end

@implementation APFormattedStringTest

- (APFormattedString*) createTestString {
    APFormattedString *string =
        [[[[[APFormattedString builder]
            appendPlain:@"Ten: %ld.", (long) 10]
            appendBold:@" Bold text."]
            appendPlain:@" Normal text."]
                build];
    return string;
}

- (void) testText {
    APFormattedString *string = [self createTestString];
    NSString* result = [string renderText];
    XCTAssertEqualObjects(result, @"Ten: 10. Bold text. Normal text.");
}

- (void) testMarkDown {
    APFormattedString *string = [self createTestString];
    NSString* result = [string renderMarkDown];
    XCTAssertEqualObjects(result, @"Ten: 10.** Bold text.** Normal text.");
}

@end
