//
//  XGXcodeBot.h
//  xcode-github
//
//  Created by Edward on 2/28/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark XGXcodeBotStatus

@interface XGXcodeBotStatus : NSObject
@property (strong, readonly) NSString*_Nullable botID;
@property (strong, readonly) NSString*_Nullable botName;
@property (strong, readonly) NSString*_Nullable serverName;
@property (strong, readonly) NSString*_Nullable integrationID;
@property (strong, readonly) NSNumber*_Nullable integrationNumber;
@property (strong, readonly) NSString*_Nullable result;
@property (strong, readonly) NSString*_Nullable currentStep;
@property (strong, readonly) NSDictionary*_Nullable dictionary;
@property (strong, readonly) NSError*_Nullable  error;

@property (strong, readonly) NSDate*_Nullable queuedDate;
@property (strong, readonly) NSDate*_Nullable startedDate;
@property (strong, readonly) NSDate*_Nullable endedDate;

@property (strong, readonly) NSNumber*_Nullable errorCount;
@property (strong, readonly) NSNumber*_Nullable warningCount;
@property (strong, readonly) NSNumber*_Nullable analyzerWarningCount;
@property (strong, readonly) NSNumber*_Nullable testsCount;
@property (strong, readonly) NSNumber*_Nullable testFailureCount;
@property (strong, readonly) NSNumber*_Nullable codeCoveragePercentage;

- (instancetype _Nonnull) initWithServerName:(NSString*_Nullable)serverName
                                  dictionary:(NSDictionary*_Nullable)dictionary
                                  NS_DESIGNATED_INITIALIZER;
@end

#pragma mark - XGXcodeBot

@interface XGXcodeBot : NSObject
@property (strong, readonly) NSString*_Nullable name;
@property (strong, readonly) NSString*_Nullable botID;
@property (strong, readonly) NSString*_Nullable sourceControlRepository;
@property (strong, readonly) NSDictionary*_Nullable dictionary;
@property (strong, readonly) NSString*_Nullable pullRequestNumber;
@property (strong, readonly) NSString*_Nonnull  serverName;
@property (strong, readonly) NSString*_Nonnull  sourceControlWorkspaceBlueprintLocationsID;

- (instancetype _Nonnull) initWithServerName:(NSString*_Nullable)serverName
                                  dictionary:(NSDictionary*_Nullable)dictionary
                                  NS_DESIGNATED_INITIALIZER;

/// @param xcodeServerName  The network name of the Xcode server.
/// @param error            If not nil, any error encountered is returned here.
/// @returns    A dictionary with a key of the bot name and value of the bot status.
+ (NSDictionary<NSString*, XGXcodeBot*>*_Nullable) botsForServer:(NSString*_Nonnull)xcodeServerName
                                                           error:(NSError*__autoreleasing _Nullable*_Nullable)error;

+ (NSString*_Nonnull) botNameFromPRNumber:(NSString*_Nonnull)number title:(NSString*_Nonnull)title;

+ (NSString*_Nullable) gitHubPRNameFromString:(NSString*_Nullable)string;

+ (XGXcodeBot*_Nullable) duplicateBot:(XGXcodeBot*_Nonnull)templateBot
                          withNewName:(NSString*_Nonnull)newBotName
                     gitHubBranchName:(NSString*_Nonnull)branchName
                                error:(NSError*__autoreleasing _Nullable*_Nullable)error;

- (NSError*) startIntegration;
- (XGXcodeBotStatus*_Nonnull) status;
- (NSError*_Nullable) removeFromServer;
@end

NS_ASSUME_NONNULL_END
