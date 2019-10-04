/**
 @file          XGASettings.h
 @package       xcode-github-app
 @brief         The persistent settings store for the app.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <XcodeGitHub/XcodeGitHub.h>
#import "BNCEncoder.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString*_Nonnull XGACleanString(NSString*_Nullable string);

@interface XGAServer : XGServer <NSSecureCoding, NSCopying>
@end

#pragma mark XGGitHubSyncTask

@interface XGAGitHubSyncTask : BNCCoding <NSSecureCoding>
@property (copy) NSString*xcodeServer;
@property (copy) NSString*botNameForTemplate;
@end

#pragma mark - XGASettings

@interface XGASettings : BNCCoding <NSSecureCoding>
- (void) save;
- (void) clear;
- (void) validate;
+ (XGASettings*) shared;
@property (assign) BOOL dryRun;
@property (assign) BOOL showDebugMessages;
@property (assign) NSTimeInterval refreshSeconds;
@property (copy)   NSString*gitHubToken;
@property (strong, null_resettable) NSMutableDictionary<NSString*, XGAServer*>*servers;
@property (strong, null_resettable) NSMutableArray<XGAGitHubSyncTask*>*gitHubSyncTasks;
@end

NS_ASSUME_NONNULL_END
