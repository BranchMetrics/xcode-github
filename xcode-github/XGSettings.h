/**
 @file          XGSettings.h
 @package       xcode-github
 @brief         Settings store for xcode-github.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "XGGitHubPullRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface XGSettings : NSObject

+ (XGSettings*) sharedSettings;
- (NSString*_Nullable) gitHubStatusForPR:(XGGitHubPullRequest*)pr;
- (void) setGitHubStatus:(NSString*)sha forPR:(XGGitHubPullRequest*)pr;

@end

NS_ASSUME_NONNULL_END
