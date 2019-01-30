/**
 @file          XGCommand.m
 @package       xcode-github
 @brief         Main body of the xcode-github app.

 @author        Edward Smith
 @date          April 24, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGCommand.h"
#import "XGXcodeBot.h"
#import "XGGitHubPullRequest.h"
#import "XGSettings.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"
#include <sysexits.h>

#pragma mark Bot Functions

NSError*_Nullable XGCreateBotWithOptions(
        XGCommandOptions*_Nonnull options,
        XGGitHubPullRequest*_Nonnull pr,
        XGXcodeBot*_Nonnull templateBot,
        NSString*_Nonnull newBotName
    ) {
    if (options.dryRun) {
        BNCLog(@"Would create bot '%@'.", newBotName);
        return nil;
    }
    NSError *error = nil;
    BNCLogDebug(@"Creating bot '%@'...", newBotName);
    [pr setStatus:XGPullRequestStatusPending
        message:@"Creating Xcode bot..."
        statusURL:nil];
    [templateBot duplicateBotWithNewName:newBotName
        branchName:pr.branch
        gitHubPullRequestNumber:pr.number
        gitHubPullRequestTitle:pr.title
        error:&error];
    if (error) {
        if (error.code == -999) {
            BNCLogError(@"Can't create Xcode bot, permission error: %@.", error);
        } else {
            BNCLogError(@"Can't create Xcode bot: %@.", error);
        }
    }
    return error;
}

NSError*_Nullable XGDeleteBotWithOptions(
        XGCommandOptions*_Nonnull options,
        XGXcodeBot*_Nonnull bot
    ) {
    NSError*error = nil;
    if (options.dryRun) {
        BNCLog(@"Would delete bot '%@'.", bot.name);
        return error;
    }
    BNCLogDebug(@"Deleting old bot '%@'...", bot.name);
    error = [bot deleteBot];
    if (error) {
        BNCLogError(
            @"Can't remove old bot named '%@' from server: %@.", bot.name, error
        );
        return error;
    }
    [[XGSettings sharedSettings]
        deleteGitHubStatusForRepoOwner:bot.repoOwner
        repoName:bot.repoName
        branch:bot.branch];
    return error;
}

NSError*_Nullable XGUpdatePRStatusOnGitHub(
        XGCommandOptions*_Nonnull options,
        XGGitHubPullRequest*_Nonnull pr,
        XGXcodeBotStatus*_Nonnull botStatus
    ) {
    NSError*error = nil;
    XGPullRequestStatus status = XGPullRequestStatusError;

    /*
    XGXcodeBotStatus:

    XGPullRequestStatusError,
    XGPullRequestStatusFailure,
    XGPullRequestStatusPending,
    XGPullRequestStatusSuccess,
    */

    NSSet<NSString*>*failureResults = [NSSet setWithArray:@[
        @"build-errors",
        @"test-failures",
        @"build-failed",
        @"canceled",
    ]];
    NSSet<NSString*>*successResults = [NSSet setWithArray:@[
        @"succeeded",
        @"warnings",
        @"analyzer-warnings",
    ]];

    if ([botStatus.currentStep isEqualToString:@"completed"]) {
        if (botStatus.result == nil) {
        } else
        if ([successResults containsObject:botStatus.result]) {
            status = XGPullRequestStatusSuccess;
        } else
        if ([failureResults containsObject:botStatus.result]) {
            status = XGPullRequestStatusFailure;
        } else {
            status = XGPullRequestStatusError;
        }
    } else {
        status = XGPullRequestStatusPending;
    }

    NSString*message = botStatus.summaryString;
    NSString*statusHash = [NSString stringWithFormat:@"%@:%@",
        NSStringFromXGPullRequestStatus(status), message];

    NSString*lastStatusHash =
        [[XGSettings sharedSettings]
            gitHubStatusForRepoOwner:pr.repoOwner
            repoName:pr.repoName
            branch:pr.branch];

    if (lastStatusHash == nil) {
        // Get the most recent status from GitHub:
        XGGitHubPullRequestStatus *status = [[pr statusesWithError:nil] firstObject];
        if (status) {
            lastStatusHash = [NSString stringWithFormat:@"%@:%@",
                NSStringFromXGPullRequestStatus(status.status), status.message];
            [[XGSettings sharedSettings]
                setGitHubStatus:lastStatusHash
                forRepoOwner:pr.repoOwner
                repoName:pr.repoName
                branch:pr.branch];
        }
    }

    if ([lastStatusHash isEqualToString:statusHash])
        return nil;

    if (options.dryRun) {
        BNCLog(@"Would update PR#%@ with status %@: %@.",
            pr.number, NSStringFromXGPullRequestStatus(status), message);
        return nil;
    }

    error = [pr setStatus:status
        message:message
        statusURL:nil];
    if (error) return error;

    // Add a completion message to the PR:
    if ([botStatus.currentStep isEqualToString:@"completed"]) {
        error = [pr addComment:[botStatus.formattedDetailString renderMarkDown]];
        if (error) return error;
    }

    [[XGSettings sharedSettings]
        setGitHubStatus:statusHash
        forRepoOwner:pr.repoOwner
        repoName:pr.repoName
        branch:pr.branch];

    return nil;
}

NSError* XGShowXcodeBotStatus(XGCommandOptions* options) {
    // Update the bots and display the results:

    XGServer*xcodeServer = [[XGServer alloc] init];
    xcodeServer.server = options.xcodeServerName;
    xcodeServer.user = options.xcodeServerUser;
    xcodeServer.password = options.xcodeServerPassword;

    // Allow self-signed certs from the xcode server:
    [BNCNetworkService shared].allowAnySSLCert = YES;

    BNCLogDebug(@"Refreshing Xcode bot status...");
    NSError *error = nil;
    NSDictionary<NSString*, XGXcodeBot*> *bots = [XGXcodeBot botsForServer:xcodeServer error:&error];
    if (error) {
        BNCLogError(@"Can't retrieve Xcode bot information from '%@': %@.",
            xcodeServer.server, error);
        return error;
    }

    if (bots.count == 0) {
        BNCLog(@"Xcode bot status: No Xcode bots.");
    } else {
        BNCLog(@"Xcode bot status:");
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            XGXcodeBotStatus *status = [bot status];
            BNCLog(@"%@", status);
        }
    }
    return nil;
}

#pragma mark - Main Function

NSError*_Nullable XGUpdateXcodeBotsWithGitHub(XGCommandOptions*_Nonnull options) {
    NSError *error = nil;
    int returnCode = EXIT_FAILURE;
    {
        XGServer*xcodeServer = [[XGServer alloc] init];
        xcodeServer.server = options.xcodeServerName;
        xcodeServer.user = options.xcodeServerUser;
        xcodeServer.password = options.xcodeServerPassword;

        // Allow self-signed certs from the xcode server:
        [BNCNetworkService shared].allowAnySSLCert = YES;

        BNCLogDebug(@"Getting Xcode bots on '%@'...", options.xcodeServerName);
        NSDictionary<NSString*, XGXcodeBot*> *bots =
            [XGXcodeBot botsForServer:xcodeServer error:&error];
        if (error) {
            BNCLogError(@"Can't retrieve Xcode bot information from %@: %@.",
                options.xcodeServerName, error);
            returnCode = EX_NOHOST;
            goto exit;
        }
        if (options.showStatusOnly) {
            error = XGShowXcodeBotStatus(options);
            if (!error) returnCode = EXIT_SUCCESS;
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

        // Check for open pull requests with state 'open':
        for (XGGitHubPullRequest *pr in pullRequests.objectEnumerator) {
            NSString *newBotName = [XGXcodeBot botNameFromPRNumber:pr.number title:pr.title];
            XGXcodeBot *bot = bots[newBotName];
            if ([pr.state isEqualToString:@"open"]) {
                if (bot) {
                    error = XGUpdatePRStatusOnGitHub(options, pr, bot.status);
                } else {
                    error = XGCreateBotWithOptions(options, pr, templateBot, newBotName);
                }
                if (error) {
                    returnCode = EX_NOPERM;
                    goto exit;
                }
            }
        }

        // Check for bots with no PR and delete it:
        for (XGXcodeBot *bot in bots.objectEnumerator) {
            NSString *number = bot.pullRequestNumber;
            if (number && !pullRequests[number]) {
                error = XGDeleteBotWithOptions(options, bot);
                if (error) { returnCode = EX_NOPERM; goto exit; }
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
