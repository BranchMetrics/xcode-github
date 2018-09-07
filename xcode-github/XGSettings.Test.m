/**
 @file          XGSettings.Test.m
 @package       xcode-github
 @brief         Tests for XGSettings.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "XGSettings.h"

@interface XGSettingsTest : BNCTestCase
@end

@implementation XGSettingsTest

- (void) testXGSettings {
    XGSettings*settings = [XGSettings sharedSettings];
    XCTAssertNotNil(settings);

    // Status1
    NSString*kStatus1 = @"status1";
    XGGitHubPullRequest*pr1 = [[XGGitHubPullRequest alloc] initWithDictionary:@{
        @"head": @{
            @"ref": @"pr1",
            @"repo": @{
                @"full_name": @"owner/name"
            }
        }
    }];
    XCTAssertEqualObjects(pr1.repoOwner, @"owner");
    XCTAssertEqualObjects(pr1.repoName,  @"name");
    XCTAssertEqualObjects(pr1.branch,    @"pr1");

    [settings setGitHubStatus:kStatus1 forPR:pr1];
    NSString*test = [settings gitHubStatusForPR:pr1];
    XCTAssertEqualObjects(test, kStatus1);

    // Status2
    NSString*kStatus2 = @"status2";
    XGGitHubPullRequest*pr2 = [[XGGitHubPullRequest alloc] initWithDictionary:@{
        @"head": @{
            @"ref": @"pr2",
            @"repo": @{
                @"full_name": @"owner/name2"
            }
        }
    }];
    XCTAssertEqualObjects(pr2.repoOwner, @"owner");
    XCTAssertEqualObjects(pr2.repoName,  @"name2");
    XCTAssertEqualObjects(pr2.branch,    @"pr2");

    [settings setGitHubStatus:kStatus2 forPR:pr2];
    test = [settings gitHubStatusForPR:pr2];
    XCTAssertEqualObjects(test, kStatus2);

    test = [settings gitHubStatusForPR:pr1];
    XCTAssertEqualObjects(test, kStatus1);
}

- (void) testExpiration {
    XCTAssert(NO, @"TODO: Test data expiration.");
}

@end
