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
    [settings setGitHubStatus:@"Status1" forRepoOwner:@"owner" repoName:@"name1" branch:@"pr1"];
    NSString*test = [settings gitHubStatusForRepoOwner:@"owner" repoName:@"name1" branch:@"pr1"];
    XCTAssertEqualObjects(test, @"Status1");

    // Status2
    [settings setGitHubStatus:@"Status2" forRepoOwner:@"owner" repoName:@"name2" branch:@"pr2"];
    test = [settings gitHubStatusForRepoOwner:@"owner" repoName:@"name2" branch:@"pr2"];
    XCTAssertEqualObjects(test, @"Status2");

    test = [settings gitHubStatusForRepoOwner:@"owner" repoName:@"name1" branch:@"pr1"];
    XCTAssertEqualObjects(test, @"Status1");
}

- (void) testExpiration {
    XGSettings*settings = [XGSettings sharedSettings];
    XCTAssertNotNil(settings);

    // Set & check Status1
    [settings setGitHubStatus:@"Status1" forRepoOwner:@"owner" repoName:@"name1" branch:@"pr1"];
    NSString*test = [settings gitHubStatusForRepoOwner:@"owner" repoName:@"name1" branch:@"pr1"];
    XCTAssertEqualObjects(test, @"Status1");

    settings.dataExpirationSeconds = 5.0;
    sleep(7);
    test = [settings gitHubStatusForRepoOwner:@"owner" repoName:@"name1" branch:@"pr1"];
    XCTAssertNil(test);
}

@end
