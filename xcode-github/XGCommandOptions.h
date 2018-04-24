//
//  XGCommandOptions.h
//  xcode-github
//
//  Created by Edward on 3/7/18.
//  Copyright © 2018 Branch. All rights reserved.
//

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

- (instancetype _Nonnull) initWithArgc:(int)argc argv:(char*const _Nullable[_Nullable])argv;
+ (instancetype _Nonnull) testWithBranchSDK;
+ (instancetype _Nonnull) testWithBranchLabs;
@end

NS_ASSUME_NONNULL_END
