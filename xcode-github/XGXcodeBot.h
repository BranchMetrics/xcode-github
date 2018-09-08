/**
 @file          XGXcodeBot.h
 @package       xcode-github
 @brief         A class for working with Xcode bot statuses.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "APPFormattedString.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark XGXcodeBotStatus

@interface XGXcodeBotStatus : NSObject
@property (strong, readonly) NSString*_Nullable botID;
@property (strong, readonly) NSString*_Nullable botName;
@property (strong, readonly) NSString*_Nullable serverName;
@property (strong, readonly) NSString*_Nullable integrationID;
@property (strong, readonly) NSNumber*_Nullable integrationNumber;
/**
  currentStep possible values:
    "pending"
    "preparing"
    "checkout"
    "before-triggers"
    "building"
    "testing"
    "archiving"
    "processing"
    "after-triggers"
    "uploading"
    "completed"
*/
@property (strong, readonly) NSString*_Nullable currentStep;
/**
 result possible values:
    "unknown"
    "succeeded"
    "build-errors"
    "test-failures"
    "warnings"
    "analyzer-warnings"
    "build-failed"
    "checkout-error"
    "internal-error"
    "internal-checkout-error"
    "internal-build-error"
    "internal-processing-error"
    "canceled"
    "trigger-error"
*/
@property (strong, readonly) NSString*_Nullable result;
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

@property (strong, readonly) NSArray<NSString*>*_Nullable tags;

- (instancetype _Nonnull) initWithServerName:(NSString*_Nullable)serverName
                                  dictionary:(NSDictionary*_Nullable)dictionary
                                  NS_DESIGNATED_INITIALIZER;

- (NSString*) summaryString;
- (APPFormattedString*) formattedDetailString;
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

@property (strong, readonly) NSString*_Nonnull repoOwner;
@property (strong, readonly) NSString*_Nonnull repoName;
@property (strong, readonly) NSString*_Nonnull branch;

+ (instancetype _Nonnull) new NS_UNAVAILABLE;

- (instancetype _Nonnull) init NS_UNAVAILABLE;

- (instancetype _Nonnull) initWithServerName:(NSString*_Nullable)serverName
                                  dictionary:(NSDictionary*_Nullable)dictionary
                                  NS_DESIGNATED_INITIALIZER;

/// @param xcodeServerName  The network name of the Xcode server.
/// @param error            If not nil, any error encountered is returned here.
/// @return A dictionary with a key of the bot name and value of the bot status.
+ (NSDictionary<NSString*, XGXcodeBot*>*_Nullable) botsForServer:(NSString*_Nonnull)xcodeServerName
                                                           error:(NSError*__autoreleasing _Nullable*_Nullable)error;

+ (NSString*_Nonnull) botNameFromPRNumber:(NSString*_Nonnull)number title:(NSString*_Nonnull)title;

+ (NSString*_Nullable) gitHubPRNameFromString:(NSString*_Nullable)string;

+ (XGXcodeBot*_Nullable) duplicateBot:(XGXcodeBot*_Nonnull)templateBot
                          withNewName:(NSString*_Nonnull)newBotName
                     gitHubBranchName:(NSString*_Nonnull)branchName
                                error:(NSError*__autoreleasing _Nullable*_Nullable)error;

- (NSError*_Nullable) startIntegration;
- (XGXcodeBotStatus*_Nonnull) status;
- (NSError*_Nullable) removeFromServer;
@end

NS_ASSUME_NONNULL_END
