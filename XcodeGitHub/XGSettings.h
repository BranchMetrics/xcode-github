/**
 @file          XGSettings.h
 @package       xcode-github
 @brief         Settings store for xcode-github.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGSettings : NSObject

+ (XGSettings*) sharedSettings;

- (NSString*_Nullable) gitHubStatusForRepoOwner:(NSString*)repoOwner
    repoName:(NSString*)repoName
    branch:(NSString*)branch;

- (void) setGitHubStatus:(NSString*)status
    forRepoOwner:(NSString*)repoOwner
    repoName:(NSString*)repoName
    branch:(NSString*)branch;

- (void) deleteGitHubStatusForRepoOwner:(NSString*)repoOwner
    repoName:(NSString*)repoName
    branch:(NSString*)branch;

/// Clears all settings.
- (void) clear;

/// Time in seconds to expire old entries. Defaults 30 days.
@property (assign) NSTimeInterval dataExpirationSeconds;
@end

NS_ASSUME_NONNULL_END
