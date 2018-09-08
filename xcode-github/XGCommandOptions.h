/**
 @file          XGCommandOptions.h
 @package       xcode-github
 @brief         Command options for the xcode-github app.

 @author        Edward Smith
 @date          March 7, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XGCommandOptions : NSObject
@property (strong) NSString*_Nullable xcodeServerName;
@property (strong) NSString*_Nullable templateBotName;
@property (strong) NSString*_Nullable githubAuthToken;
@property (assign) int  verbosity;
@property (assign) BOOL dryRun;
@property (assign) BOOL showStatusOnly;
@property (assign) BOOL showVersion;
@property (assign) BOOL showHelp;
@property (assign) BOOL badOptionsError;
@property (assign) BOOL repeatForever;

- (instancetype _Nonnull) initWithArgc:(int)argc argv:(char*const _Nullable[_Nullable])argv;
+ (instancetype _Nonnull) testWithBranchSDK;
+ (instancetype _Nonnull) testWithBranchLabs;
@end

NS_ASSUME_NONNULL_END
