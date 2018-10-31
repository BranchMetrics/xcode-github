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

NS_ASSUME_NONNULL_BEGIN

/**
 Creates or updates an Xcode bot when a new GitHub pull request is created on a GitHub project.

 @param  options The options for the new bot. The options specify the Xcode server, and the template bot.
 @return Returns an error if one occurs else nil.
*/
FOUNDATION_EXPORT NSError*_Nullable XGUpdateXcodeBotsWithGitHub(XGCommandOptions* options);

/**
 Writes the current Xcode server status to the output device.

 @param  options The command options with the Xcode server, user, and pass of which to show the status.
 @return Returns an NSError if an error occurs or nil on success.
*/
FOUNDATION_EXPORT NSError*_Nullable XGShowXcodeBotStatus(XGCommandOptions* options);

NS_ASSUME_NONNULL_END
