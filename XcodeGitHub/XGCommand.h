/**
 @file          XGCommand.h
 @package       xcode-github
 @brief         Main body of the xcode-github app.

 @author        Edward Smith
 @date          April 24, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "XGCommandOptions.h"

/**
 Creates or updates an Xcode bot when a new GitHub pull request is created on a GitHub project.

 @param  options The options for the new bot. The options specify the Xcode server, and the template bot.
 @return Returns an error if one occurs else nil.
*/
FOUNDATION_EXPORT NSError*_Nullable XGUpdateXcodeBotsWithGitHub(XGCommandOptions*_Nonnull options);

/**
 Writes the current Xcode server status to the log.

 @param  xcodeServerName The name of the Xcode server of which to log the status.
 @return Returns an NSError if an error occurs or nil on success.
*/
FOUNDATION_EXPORT NSError*_Nullable XGLogXcodeBotStatus(NSString*_Nonnull xcodeServerName);
