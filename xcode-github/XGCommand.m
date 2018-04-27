//
//  XGCommand.m
//  xcode-github
//
//  Created by Edward on 4/24/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGCommand.h"
#import "BNCLog.h"
#import "XGXcodeBot.h"
#import "XGGitHubPullRequest.h"
#include <sysexits.h>

NSError*_Nullable XGUpdateXcodeBotsWithGitHub(XGCommandOptions*_Nonnull options) {
    NSError *error = nil;
    int returnCode = EXIT_FAILURE;
    {
        BNCLogDebug(@"Getting Xcode bots on '%@'...", options.xcodeServerName);

        NSDictionary<NSString*, XGXcodeBot*> *bots =
            [XGXcodeBot botsForServer:options.xcodeServerName error:&error];
        if (error) {
            BNCLogError(@"Can't retrieve Xcode bot information from %@: %@.",
                options.xcodeServerName, error);
            returnCode = EX_NOHOST;
            goto exit;
        }

        // Check that the template bot exists:
        XGXcodeBot *templateBot = bots[options.templateBotName];
        if (!templateBot) {
            BNCLogError(@"Can't find Xcode template bot named '%@'.", options.templateBotName);
            returnCode = EX_CONFIG;
            goto exit;
        }

        BNCLogDebug(@"Getting pull requests for '%@'...", templateBot.sourceControlRepository);

        NSDictionary<NSString*, XGGitHubPullRequest*> *pullRequests =
            [XGGitHubPullRequest pullsRequestsForRepository:templateBot.sourceControlRepository
                authToken:options.githubAuthToken
                error:&error];
        if (error) {
            BNCLogError(@"Can't retrieve pull requests from '%@': %@.",
            templateBot.sourceControlRepository, error);
            returnCode = EX_NOHOST;
            goto exit;
        }

        // Check for open pull requests with state 'open' and no bot:
        for (XGGitHubPullRequest *pr in pullRequests.objectEnumerator) {
            NSString *newBotName = [XGXcodeBot botNameFromPRNumber:pr.number title:pr.title];
            XGXcodeBot *bot = bots[newBotName];
            if ([pr.state isEqualToString:@"open"] && !bot) {
                if (options.dryRun) {
                    BNCLog(@"Would create bot '%@'.", newBotName);
                } else {
                    BNCLogDebug(@"Creating bot '%@'...", newBotName);
                    error = nil;
                    [pr setStatus:XGPullRequestStatusPending
                        message:@"Creating Xcode bot..."
                        statusURL:nil
                        authToken:options.githubAuthToken];
                    [XGXcodeBot duplicateBot:templateBot
                        withNewName:newBotName
                        gitHubBranchName:pr.branch
                        error:&error];
                    if (error) {
                        BNCLogError(@"Can't create Xcode bot: %@.", error);
                        returnCode = EX_NOPERM;
                        goto exit;
                    }
                }
            }
        }

        // Check for bots with no PR and delete it:
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            NSString *number = bot.pullRequestNumber;
            if (number && !pullRequests[number]) {
                if (options.dryRun) {
                    BNCLog(@"Would delete bot '%@'.", bot.name);
                } else  {
                    BNCLogDebug(@"Deleting old bot '%@'...", bot.name);
                    error = [bot removeFromServer];
                    if (error) {
                        BNCLogError(
                            @"Can't remove old bot named '%@' from server: %@.", bot.name, error
                        );
                        returnCode = EX_NOPERM;
                        goto exit;
                    }
                }
            }
        }

        error = nil;
        returnCode = EXIT_SUCCESS;
    }

exit:
    if (returnCode != EXIT_SUCCESS) {
        if (!error) error = [NSError errorWithDomain:NSMachErrorDomain code:KERN_FAILURE userInfo:nil];
        NSMutableDictionary *userInfo =
            ([error.userInfo isKindOfClass:NSDictionary.class])
            ? [error.userInfo mutableCopy]
            : [NSMutableDictionary new];
        userInfo[@"return_code"] = @(returnCode);
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    return error;
}
