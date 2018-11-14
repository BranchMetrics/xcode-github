/**
 @file          XcodeGitHub.h
 @package       xcode-github
 @brief         XcodeGitHub umbrella header file.

 @author        Edward Smith
 @date          October 7, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "APFormattedString.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"
#import "XGCommand.h"
#import "XGCommandOptions.h"
#import "XGGitHubPullRequest.h"
#import "XGXcodeBot.h"

FOUNDATION_EXPORT NSString*_Nonnull XGVersion(void);
