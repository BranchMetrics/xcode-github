/**
 @file          APPFormattedString.Test.m
 @package       xcode-github-app
 @brief         Tests for APPFormattedString.

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
        [[[APFormattedString
            plainText:@"Ten: %ld.", (long) 10]
            boldText:@" Bold text."]
            plainText:@" Normal text."];
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
    XCTAssertEqualObjects(result, @"Ten: 10. **Bold text**. Normal text.");

    string = [APFormattedString boldText:@"All bold"];
    result = [string renderMarkDown];
    XCTAssertEqualObjects(result, @"**All bold**");
}

- (void) testSubstring {
    NSRange r;

    r = [@"Hello" rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, 0);
    XCTAssertEqual(r.length, 5);

    r = [@"  ...Hello" rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, 5);
    XCTAssertEqual(r.length, 5);

    r = [@"Hello...  " rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, 0);
    XCTAssertEqual(r.length, 5);

    r = [@"  ...Hello...  " rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, 5);
    XCTAssertEqual(r.length, 5);

    r = [@"  ...He'll 'o...  " rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, 5);
    XCTAssertEqual(r.length, 8);

    r = [@"" rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, NSNotFound);

    r = [@"................." rangeOfAlphanumericSubstring];
    XCTAssertEqual(r.location, NSNotFound);
}

@end
