/**
 @file          XGAStatusViewItem.h
 @package       xcode-github-app
 @brief         The status view detail line.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <XcodeGitHub/XcodeGitHub.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGAStatusViewItem : NSObject
@property (strong) NSString*_Nullable server;
@property (copy)   NSString*_Nullable botName;

@property (strong) NSImage  *_Nullable statusImage;
@property (strong) APFormattedString*_Nullable statusSummary;
@property (strong) APFormattedString*_Nullable statusDetail;

@property (copy)   NSString*_Nullable repository;
@property (copy)   NSString*_Nullable branchOrPRName;

@property (copy)   NSString*_Nullable templateBotName;
@property (copy)   NSNumber*_Nullable botIsFromTemplate;

+ (instancetype) newItemWithBot:(XGXcodeBot*)bot status:(XGXcodeBotStatus*)botStatus;

@property (strong, readonly) XGXcodeBot*_Nullable bot;
@property (strong, readonly) XGXcodeBotStatus*_Nullable botStatus;
@property (assign, readonly) BOOL hasGitHubRepo;
@property (assign, readonly) BOOL isXGAMonitored;
@end

NS_ASSUME_NONNULL_END
