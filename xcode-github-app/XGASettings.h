/**
 @file          XGASettings.h
 @package       xcode-github-app
 @brief         The persistent settings store for the app.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark XGAServerSetting

@interface XGAServerSetting : NSObject
@property (strong) NSString*server;
@property (strong) NSString*user;
@property (strong) NSString*password;
@end

#pragma mark XGAServerGitHubSyncTask

@interface XGAServerGitHubSyncTask : NSObject
@property (strong, readonly) NSString*xcodeServer;
@property (strong, readonly) NSString*xcodeUser;
@property (strong, readonly) NSString*xcodePassword;

@property (strong, readonly) NSString*gitHubRepo;
@property (strong, readonly) NSString*gitHubToken;
@property (strong)           NSString*templateBotName;

- (void) setXcodeServerName:(NSString*)serverName userPassword:(NSString*_Nullable)userPassword;
- (void) setGitHubRepo:(NSString*)gitHubRepo gitHubToken:(NSString*_Nullable)token;

- (NSDictionary*) dictionary;
+ (XGAServerGitHubSyncTask*) serverGitHubSyncTaskWithDictionary:(NSDictionary*)dictionary;
@end

#pragma mark - XGASettings

@interface XGASettings : NSObject
+ (XGASettings*) shared;
- (void) save;
@property (assign) BOOL dryRun;
@property (assign) BOOL hasRunBefore;
@property (assign) BOOL showDebugMessages;
@property (assign) NSTimeInterval refreshSeconds;
@property (strong) NSMutableArray<XGAServerSetting*>*servers;
@property (strong) NSMutableArray<XGAServerGitHubSyncTask*>*serverGitHubSyncTasks;
@end

NS_ASSUME_NONNULL_END
