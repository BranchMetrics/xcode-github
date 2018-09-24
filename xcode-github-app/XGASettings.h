/**
 @file          XGASettings.h
 @package       xcode-github-app
 @brief         The persistent settings store for the app.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "BNCEncoder.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark XGAServerSetting

@interface XGAServerSetting : BNCCoding <NSSecureCoding>
@property (strong) NSString*_Nullable server;
@property (strong) NSString*_Nullable user;
@property (strong) NSString*_Nullable password;
@end

#pragma mark XGGitHubSyncTask

@interface XGAGitHubSyncTask : BNCCoding <NSSecureCoding>
@property (strong) XGAServerSetting*xcodeServer;
@property (copy)   NSString*templateBotName;
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
@property (strong) NSString*gitHubToken;
@property (strong, null_resettable) NSMutableArray<XGAServerSetting*>*servers;
@property (strong, null_resettable) NSMutableArray<XGAGitHubSyncTask*>*gitHubSyncTasks;
@end

NS_ASSUME_NONNULL_END
