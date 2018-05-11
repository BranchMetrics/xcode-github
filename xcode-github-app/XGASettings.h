//
//  XGASettings.h
//  xcode-github-app
//
//  Created by Edward on 4/24/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark XGAServerGitHubPair

@interface XGAServerGitHubSyncTask : NSObject
@property (strong, readonly) NSString*xcodeServerName;
@property (strong, readonly) NSString*xcodeServerUserPassword;
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
@property (assign) NSTimeInterval refreshSeconds;
@property (strong) NSMutableArray<XGAServerGitHubSyncTask*>*serverGitHubSyncTasks;
@end

NS_ASSUME_NONNULL_END
