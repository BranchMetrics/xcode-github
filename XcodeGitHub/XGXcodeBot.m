/**
 @file          XGXcodeBot.m
 @package       xcode-github
 @brief         A class for working with Xcode bot statuses.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGXcodeBot.h"
#import "XGUtility.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"
#import "APFormattedString.h"

@implementation XGServer

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    _server = @"";
    _user = @"";
    _password = @"";
    return self;
}

- (NSString*) description {
    NSString *pass = self.password.length ? @"'••••'" : @"nil";
    return [NSString stringWithFormat:@"<%@ %p %@ u:'%@' p:%@>",
        NSStringFromClass(self.class),
        (void*)self,
        self.server,
        self.user,
        pass];
}

@end

#pragma mark - XGXcodeBotStatus

@interface XGXcodeBotStatus ()
@property (readwrite) NSString*_Nullable serverName;
@property (readwrite) NSString*_Nullable botID;
@property (readwrite) NSString*_Nullable botName;
@property (readwrite) NSString*_Nullable integrationID;
@property (readwrite) NSNumber*_Nullable integrationNumber;
@property (readwrite) NSString*_Nullable currentStep;
@property (readwrite) NSString*_Nullable result;
@property (readwrite) NSDictionary*_Nullable dictionary;
@property (readwrite) NSError*_Nullable  error;
@end

@implementation XGXcodeBotStatus : NSObject

- (instancetype) init {
    self = [self initWithServerName:nil dictionary:nil];
    return self;
}

- (instancetype) initWithServerName:(NSString*)serverName dictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return self;

    _serverName = [serverName copy];
    _dictionary = dictionary;
    _botID = _dictionary[@"bot"][@"_id"];
    _botName = _dictionary[@"bot"][@"name"];
    _botTinyID = _dictionary[@"bot"][@"tinyID"];
    _integrationID = _dictionary[@"_id"];
    _integrationNumber = _dictionary[@"number"];
    _result = _dictionary[@"result"];
    _currentStep = _dictionary[@"currentStep"];
    _tags = _dictionary[@"tags"];

    NSDateFormatter *dateFormatter = [NSDateFormatter dateFormatter8601];
    _queuedDate = [dateFormatter dateFromString:_dictionary[@"queuedDate"]];
    _startedDate = [dateFormatter dateFromString:_dictionary[@"startedTime"]];
    _endedDate = [dateFormatter dateFromString:_dictionary[@"endedTime"]];

    NSDictionary *summary = _dictionary[@"buildResultSummary"];
    _errorCount = summary[@"errorCount"];
    _warningCount = summary[@"warningCount"];
    _analyzerWarningCount = summary[@"analyzerWarningCount"];
    _testsCount = summary[@"testsCount"];
    _testFailureCount = summary[@"testFailureCount"];
    _codeCoveragePercentage = summary[@"codeCoveragePercentage"];

    return self;
}

- (NSString*) description {
    return [NSString stringWithFormat:
        @"<%@ %p %@ #%@. Step: '%@' Result: '%@'>",
        NSStringFromClass(self.class),
        (void*)self,
        self.botName,
        self.integrationNumber,
        self.currentStep,
        self.result];
}

- (NSString*) summaryString {
    NSString *summary = nil;
    if ([self.currentStep isEqualToString:@"completed"]) {
        summary = self.result;
    } else
    if (self.currentStep.length) {
        summary = self.currentStep;
    } else {
        summary = @"unknown";
    }
    summary = [[summary stringByReplacingOccurrencesOfString:@"-" withString:@" "] capitalizedString];
    return summary;
}

/*
Theirs:

Result of [Integration 2](https://stlt.herokuapp.com/v1/xcs_deeplink/qabot.stage.branch.io/b388335146db7e936b7215574d28037e/742d12409905670706fa2c837a41b416)
---
*Duration*: 8 minutes and 32 seconds
*Result*: **Perfect build!** All 199 tests passed. :+1:
*Test Coverage*: 60%

Mine:

**Result of Integration 1**
---
_Duration_: 10 minutes, 2 seconds
_Result_: **Perfect build**! 👍
_Test Coverage_: 65% (193 tests).
*/

- (APFormattedString*) formattedDetailString {
    NSTimeInterval duration = [self.endedDate timeIntervalSinceDate:self.startedDate];
    NSString*durationString = XGDurationStringFromTimeInterval(duration);

    APFormattedString *apstring =
        [[[[APFormattedString
            plainText:@"Result of Integration %@", self.integrationNumber]
            line]
            italicText:@"Duration"]
            plainText:@": %@\n", durationString];

    if ([self.result isEqualToString:@"canceled"]) {
        [[[apstring
            plainText:@"Build was "]
            boldText:@"**manually canceled**"]
            plainText:@"."];
        return apstring;
    }
    
    [[apstring
        italicText:@"Result"]
        plainText:@": "];

    if ([self.errorCount integerValue] > 0) {
        [apstring boldText:@"%@ errors, failing state: %@", self.errorCount, self.summaryString];
        return apstring;
    }

    if ([self.testFailureCount integerValue] > 0) {
        [[apstring boldText:@"Build failed %@ tests", self.testFailureCount]
            plainText:@" out of %@", self.testsCount];
        return apstring;
    }

    if ([self.testsCount integerValue] > 0 &&
        [self.warningCount integerValue] > 0 &&
        [self.analyzerWarningCount integerValue] > 0) {
        [[[[[apstring
            plainText:@"All %@ tests passed, but please ", self.testsCount]
            boldText:@"fix %@ warnings", self.warningCount]
            plainText:@" and "]
            boldText:@"%@ analyzer warnings", self.analyzerWarningCount]
            plainText:@"."];
        if ([self.codeCoveragePercentage doubleValue] > 0) {
            [[apstring
                italicText:@"\nTest Coverage"]
                plainText:@": %@%%", self.codeCoveragePercentage];
        }
        return apstring;
    }

    if ([self.testsCount integerValue] > 0 &&
        [self.warningCount integerValue] > 0) {
        [[apstring
            plainText:@"All %@ tests passed, but please ", self.testsCount]
            boldText:@"fix %@ warnings.", self.warningCount];
        if ([self.codeCoveragePercentage doubleValue] > 0) {
            [[apstring
                italicText:@"\nTest Coverage"]
                plainText:@": %@%%", self.codeCoveragePercentage];
        }
        return apstring;
    }

    if ([self.testsCount integerValue] > 0 &&
        [self.analyzerWarningCount integerValue] > 0) {
        [[apstring
            plainText:@"All %@ tests passed, but please ", self.testsCount]
            boldText:@"fix %@ analyzer warnings.", self.analyzerWarningCount];
        if ([self.codeCoveragePercentage doubleValue] > 0) {
            [[apstring
                italicText:@"\nTest Coverage"]
                plainText:@": %@%%", self.codeCoveragePercentage];
        }
        return apstring;
    }

    if ([self.errorCount integerValue] == 0 && [self.result isEqualToString:@"succeeded"]) {
        if (self.testsCount.integerValue == 0) {
            [apstring boldText:@"Perfect build! 👍"];
        } else {
            if (self.testFailureCount.integerValue == 0) {
                [apstring boldText:@"Perfect build!"];
                [apstring plainText:@" All %ld tests passed. 👍\n", (long) self.testsCount.integerValue];
                if (self.codeCoveragePercentage.doubleValue > 0.0) {
                    [[apstring
                        italicText:@"Test Coverage"]
                        plainText:@": %@%%", self.codeCoveragePercentage];
                }
            } else {
                [apstring boldText:@"Perfect build!"];
                [apstring plainText:@" But please fix %ld failing tests.\n", (long) self.testFailureCount.integerValue];
                [[apstring
                    italicText:@"Test Coverage"]
                    plainText:@": %@%% (%@ tests).", self.codeCoveragePercentage, self.testsCount];
            }
        }
        return apstring;
    }

    [apstring boldText:@"Failing state: %@.", self.summaryString];
    if ([self.tags containsObject:@"xcs-upgrade"]) {
        [apstring italicText:@"\nThe current configuration may not be supported by the Xcode upgrade."];
    }

    return apstring;
}

- (NSURL*) integrationLogURL {
    NSString*string =
        [NSString stringWithFormat:@"https://%@/xcode/internal/api/integrations/%@/assets",
            self.serverName, self.integrationID];
    NSURL*URL = [NSURL URLWithString:string];
    return URL;
}

@end

#pragma mark - XGXcodeBot

@implementation XGXcodeBot

- (instancetype) initWithServer:(XGServer*)server dictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return self;

    _server = server;
    _dictionary = dictionary;
    _name = _dictionary[@"name"];
    _botID = _dictionary[@"_id"];
    @try {
        _sourceControlRepository =
            _dictionary[@"configuration"]
                [@"sourceControlBlueprint"]
                [@"DVTSourceControlWorkspaceBlueprintRemoteRepositoriesKey"]
                [0]
                [@"DVTSourceControlWorkspaceBlueprintRemoteRepositoryURLKey"];
        NSDictionary *locations =
            _dictionary[@"configuration"]
                [@"sourceControlBlueprint"]
                [@"DVTSourceControlWorkspaceBlueprintLocationsKey"];
        _sourceControlWorkspaceBlueprintLocationsID = locations.allKeys.firstObject;

        _templateBotName = _dictionary[@"templateBotName"];
        _pullRequestNumber = _dictionary[@"pullRequestNumber"];
        _pullRequestTitle = _dictionary[@"pullRequestTitle"];
    }
    @catch(id error) {
        BNCLogError(@"Can't retrieve source control URL: %@", error);
    }

    NSRange repoRange = [self.sourceControlRepository rangeOfString:@"/" options:NSBackwardsSearch];
    if (repoRange.location != NSNotFound) {
        NSRange ownerRange = [self.sourceControlRepository rangeOfString:@"/"
            options:NSBackwardsSearch range:NSMakeRange(0, repoRange.location)];
        if (ownerRange.location == NSNotFound) {
            ownerRange = [self.sourceControlRepository rangeOfString:@":"
                options:NSBackwardsSearch range:NSMakeRange(0, repoRange.location)];
        }
        if (ownerRange.location != NSNotFound) {
            _repoOwner = [self.sourceControlRepository
                substringWithRange:NSMakeRange(ownerRange.location+1, repoRange.location - ownerRange.location - 1)];
            _repoName = [self.sourceControlRepository
                substringWithRange:NSMakeRange(
                    repoRange.location+1,
                    self.sourceControlRepository.length - repoRange.location - 1
                )];
            if ([_repoName hasSuffix:@".git"]) {
                _repoName = [_repoName substringWithRange:NSMakeRange(0, _repoName.length-4)];
            }
            NSDictionary*locations =
                _dictionary[@"configuration"][@"sourceControlBlueprint"][@"DVTSourceControlWorkspaceBlueprintLocationsKey"];
            for (NSDictionary*location in locations.objectEnumerator) {
                _branch = location[@"DVTSourceControlBranchIdentifierKey"];
            }
        }
    }

    return self;
}

+ (NSString*) botNameFromPRNumber:(NSString *)number title:(NSString *)title {
    if (!number) number = @"0";
    if (!title) title = @"<No PR Title>";
    NSString *newTitle =
        [[[[title
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            stringByReplacingOccurrencesOfString:@"\t" withString:@" "]
            stringByReplacingOccurrencesOfString:@"\n" withString:@" "]
            stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    newTitle = [NSString stringWithFormat:@"xcode-github PR#%@ %@", number, newTitle];
    return newTitle;
}

+ (NSDictionary<NSString*, XGXcodeBot*>*_Nullable) botsForServer:(XGServer*)xcodeServer
        error:(NSError*__autoreleasing _Nullable*_Nullable)error {

    NSError *localError = nil;
    NSMutableDictionary<NSString*, XGXcodeBot*>* bots = nil;
    
    {
        NSString *serverURLString =
            [NSString stringWithFormat:@"https://%@:20343/api/bots", xcodeServer.server];
        NSURL *serverURL = [NSURL URLWithString:serverURLString];
        if (!serverURL) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadURL
                    userInfo:@{
                        NSLocalizedDescriptionKey:
                            [NSString stringWithFormat:@"Bad server name '%@'.", xcodeServer.server]
                    }
                ];
            BNCLogError(@"Bad server name '%@'.", xcodeServer.server);
            goto exit;
        }

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                getOperationWithURL:serverURL completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
            }];
        if (xcodeServer.user.length > 0)
            [operation setUser:xcodeServer.user password:xcodeServer.password];
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        if (operation.error) {
            localError = operation.error;
            goto exit;
        }
        [operation deserializeJSONResponseData];
        if (operation.error) {
            localError = operation.error;
            goto exit;
        }

        NSArray *results = ((NSDictionary*)operation.responseData)[@"results"];
        if (![results isKindOfClass:NSArray.class]) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadServerResponse
                    userInfo:@{ NSLocalizedDescriptionKey: @"Expected an array." }];
            goto exit;
        }

        bots = [NSMutableDictionary new];
        for (NSDictionary *d in results) {
            XGXcodeBot *bot = [[XGXcodeBot alloc] initWithServer:xcodeServer dictionary:d];
            if (bot && bot.name) {
                bots[bot.name] = bot;
            }
        }
    }

exit:
    if (localError.code == -999) {
        localError = [NSError errorWithDomain:NSURLErrorDomain
            code:NSURLErrorUserAuthenticationRequired userInfo:@{
                NSLocalizedDescriptionKey: @"User authentication is required."
        }];
    }
    if (error) *error = localError;
    return bots;
}

- (BOOL) botIsFromTemplateBot {
    return (self.templateBotName.length == 0) ? NO : YES;
}

- (XGXcodeBotStatus*_Nonnull) status {
    NSError *localError = nil;
    XGXcodeBotStatus *status = nil;
    {
        NSString *statusString =
            [NSString stringWithFormat:
                @"https://%@:20343/api/bots/%@/integrations?last=1",
                    self.server.server, self.botID];
        NSURL *statusURL = [NSURL URLWithString:statusString];

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                getOperationWithURL:statusURL completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
            }];
        if (self.server.user.length > 0)
            [operation setUser:self.server.user password:self.server.password];
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        if (operation.error) {
            localError = operation.error;
            goto exit;
        }
        [operation deserializeJSONResponseData];
        if (operation.error) {
            localError = operation.error;
            goto exit;
        }
        NSDictionary *response =
            ([operation.responseData isKindOfClass:[NSDictionary class]])
            ? (NSDictionary*) operation.responseData : nil;
        NSArray *a = response[@"results"];
        if ([a isKindOfClass:NSArray.class]) {
            if (a.count >= 1)
                status = [[XGXcodeBotStatus alloc] initWithServerName:self.server.server dictionary:a[0]];
            else {
                status = [[XGXcodeBotStatus alloc] initWithServerName:self.server.server dictionary:nil];
                status.botID = self.botID;
                status.botName = self.name;
                status.serverName = self.server.server;
                status.integrationNumber = [NSNumber numberWithInteger:0];
                status.currentStep = @"no integrations";
                status.result = @"unknown";
            }
            goto exit;
        }

        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadServerResponse
                userInfo:@{ NSLocalizedDescriptionKey: @"Expected an array." }];
    }

exit:
    if (!status) status = [[XGXcodeBotStatus alloc] initWithServerName:self.server.server dictionary:nil];
    if (localError) status.error = localError;
    return status;
}

- (NSError*_Nullable) deleteBot {
    NSError *localError = nil;
    NSString *string = [NSString stringWithFormat:
        @"https://%@:20343/api/bots/%@", self.server.server, self.botID];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadURL
                userInfo:@{
                    NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"Bad server name '%@'.", self.server.server]
                }
            ];
        BNCLogError(@"Bad server name '%@'.", self.server.server);
        return localError;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            getOperationWithURL:URL
            completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
        }];
    operation.request.HTTPMethod = @"DELETE";
    if (self.server.user.length > 0)
        [operation setUser:self.server.user password:self.server.password];
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (operation.error) return operation.error;

    if (operation.HTTPStatusCode < 200 || operation.HTTPStatusCode >= 300) {
        localError = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
        return localError;
    }

    return nil;
}

- (XGXcodeBot*_Nullable) duplicateBotWithNewName:(NSString*_Nonnull)newBotName
                                      branchName:(NSString*_Nonnull)branchName
                         gitHubPullRequestNumber:(NSString*_Nonnull)pullRequestNumber
                          gitHubPullRequestTitle:(NSString*_Nonnull)pullRequestTitle
                                           error:(NSError*__autoreleasing _Nullable*_Nullable)error {
    XGXcodeBot *bot = nil;
    NSError *localError = nil;
    {
        // Simply using the 'duplicate' bot api and changing the git branch won't actually change
        // the git branch to the branch of the PR.
        //
        // Steps:
        // 1. Duplicate the bot.
        // 2. Get the new bot.
        // 3. Modify the bot to the new branch with a PATCH.

        //
        // Duplicate the bot:
        //

        NSString *string =
            [NSString stringWithFormat:@"https://%@:20343/api/bots/%@/duplicate",
                self.server.server, self.botID];
        NSURL *URL = [NSURL URLWithString:string];
        if (!URL) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadURL
                    userInfo:@{
                        NSLocalizedDescriptionKey:
                            [NSString stringWithFormat:@"Bad server name '%@'.", self.server.server]
                    }
                ];
            BNCLogError(@"Bad server name '%@'.", self.server.server);
            goto exit;
        }
        __auto_type dictionary = [NSMutableDictionary new];
        dictionary[@"name"] = newBotName;
        dictionary[@"templateBotName"] = self.name;
        dictionary[@"pullRequestNumber"] = pullRequestNumber;
        dictionary[@"pullRequestTitle"] = pullRequestTitle;

        NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&localError];
        if (!data) {
            localError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSKeyValueValidationError
                userInfo:@{ NSLocalizedDescriptionKey: @"Can't create bot dictionary."}];
        }
        if (localError || !data) goto exit;

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                postOperationWithURL:URL
                contentType:@"application/json"
                data:data
                completion:^(BNCNetworkOperation *operation) {
                    dispatch_semaphore_signal(semaphore);
            }];
        if (self.server.user.length > 0)
            [operation setUser:self.server.user password:self.server.password];
        [operation.request addValue:@"7" forHTTPHeaderField:@"X-XCSClientVersion"];
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (operation.error) {
            localError = operation.error;
            goto exit;
        }
        if (operation.HTTPStatusCode != 201) {
            localError = [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                    [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
            BNCLogDebug(@"Response was: %@.", [operation stringFromResponseData]);
            goto exit;
        }
        [operation deserializeJSONResponseData];
        NSDictionary *d = (id) operation.responseData;
        if (!([d isKindOfClass:NSDictionary.class] && [d[@"_id"] isKindOfClass:NSString.class])) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadServerResponse
                    userInfo:@{ NSLocalizedDescriptionKey: @"Expected an Xcode bot response." }];
            goto exit;
        }
        NSString*newBotID = d[@"_id"];

        //
        // Get the just created bot:
        //

        string =
            [NSString stringWithFormat:@"https://%@:20343/api/bots/%@",
                self.server.server, newBotID];
        URL = [NSURL URLWithString:string];
        semaphore = dispatch_semaphore_create(0);
        operation =
            [[BNCNetworkService shared]
                getOperationWithURL:URL
                completion:^(BNCNetworkOperation *operation) {
                    dispatch_semaphore_signal(semaphore);
            }];
        if (self.server.user.length > 0)
            [operation setUser:self.server.user password:self.server.password];
        [operation.request addValue:@"7" forHTTPHeaderField:@"X-XCSClientVersion"];
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (operation.error) {
            localError = operation.error;
            goto exit;
        }
        if (operation.HTTPStatusCode != 200) {
            localError = [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                    [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
            BNCLogDebug(@"Response was: %@.", [operation stringFromResponseData]);
            goto exit;
        }
        [operation deserializeJSONResponseData];
        d = (id) operation.responseData;
        if (!([d isKindOfClass:NSDictionary.class] &&
              [d[@"_id"] isKindOfClass:NSString.class] &&
              [newBotID isEqualToString:d[@"_id"]])) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadServerResponse
                    userInfo:@{ NSLocalizedDescriptionKey: @"Expected an Xcode bot response." }];
            goto exit;
        }

        //
        // Fix up the git branch of the duplicated bot:
        //

        string =
            [NSString stringWithFormat:@"https://%@:20343/api/bots/%@?overwriteBlueprint=true",
                self.server.server, newBotID];
        URL = [NSURL URLWithString:string];

        dictionary = (__bridge_transfer NSMutableDictionary*)
            CFPropertyListCreateDeepCopy(
                kCFAllocatorDefault,
                (CFDictionaryRef)d,
                kCFPropertyListMutableContainers
        );
        dictionary[@"_id"] = nil;
        dictionary[@"_rev"] = nil;
        dictionary[@"tinyID"] = nil;
        dictionary[@"configuration"]
            [@"sourceControlBlueprint"]
            [@"DVTSourceControlWorkspaceBlueprintLocationsKey"]
            [self.sourceControlWorkspaceBlueprintLocationsID]
            [@"DVTSourceControlBranchIdentifierKey"]
                = branchName;
        dictionary[@"configuration"]
            [@"sourceControlBlueprint"]
            [@"DVTSourceControlWorkspaceBlueprintRemoteRepositoryAuthenticationStrategiesKey"]
                = @{};
        dictionary[@"configuration"]
            [@"sourceControlBlueprint"]
            [@"DVTSourceControlWorkspaceBlueprintIdentifierKey"]
                = [NSUUID UUID].UUIDString;
        dictionary[@"configuration"][@"scheduleType"] = @2; // 2: On commit
        dictionary[@"sourceControlBlueprintIdentifier"] = nil;
        dictionary[@"lastRevisionBlueprint"] = nil;

        data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&localError];
        if (!data) {
            localError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSKeyValueValidationError
                userInfo:@{ NSLocalizedDescriptionKey: @"Can't create bot dictionary."}];
        }
        if (localError || !data) goto exit;

        semaphore = dispatch_semaphore_create(0);
        operation =
            [[BNCNetworkService shared]
                postOperationWithURL:URL
                contentType:@"application/json"
                data:data
                completion:^(BNCNetworkOperation *operation) {
                    dispatch_semaphore_signal(semaphore);
            }];
        if (self.server.user.length > 0)
            [operation setUser:self.server.user password:self.server.password];
        operation.request.HTTPMethod = @"PATCH";
        [operation.request addValue:@"7" forHTTPHeaderField:@"X-XCSClientVersion"];
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (operation.error) {
            localError = operation.error;
            goto exit;
        }
        if (operation.HTTPStatusCode != 200) {
            localError = [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                    [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
            BNCLogDebug(@"Response was: %@.", [operation stringFromResponseData]);
            goto exit;
        }
        [operation deserializeJSONResponseData];
        d = (id) operation.responseData;
        if ([d isKindOfClass:NSDictionary.class]) {
            bot = [[XGXcodeBot alloc] initWithServer:self.server dictionary:d];
            if (bot) {
                [bot startIntegration];
                goto exit;
            }
        }
        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadServerResponse
                userInfo:@{ NSLocalizedDescriptionKey: @"Expected an Xcode bot response." }];
    }

exit:
    if (error) *error = localError;
    return bot;
}

- (NSError*) startIntegration {
    NSError *localError = nil;
    NSString *string = [NSString stringWithFormat:
        @"https://%@:20343/api/bots/%@/integrations", self.server.server, self.botID];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadURL
                userInfo:@{
                    NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"Bad server name '%@'.", self.server.server]
                }
            ];
        BNCLogError(@"Bad server name '%@'.", self.server.server);
        return localError;
    }

    NSDictionary *dictionary = @{
        @"shouldClean": @(true)
    };

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            postOperationWithURL:URL
            JSONData:dictionary
            completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
        }];
    if (self.server.user.length > 0)
        [operation setUser:self.server.user password:self.server.password];
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (operation.error) return operation.error;

    if (operation.HTTPStatusCode != 201) {
        localError = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
        return localError;
    }

    return nil;
}

- (NSError*_Nullable) cancelIntegrationID:(NSString*)integrationID {
    NSError *localError = nil;
    NSString *string = [NSString stringWithFormat:
        @"https://%@:20343/api/integrations/%@/cancel", self.server.server, integrationID];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadURL
                userInfo:@{
                    NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"Bad server name '%@'.", self.server.server]
                }
            ];
        BNCLogError(@"Bad server name '%@'.", self.server.server);
        return localError;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            postOperationWithURL:URL
            JSONData:nil
            completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
        }];
    if (self.server.user.length > 0)
        [operation setUser:self.server.user password:self.server.password];
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (operation.error) return operation.error;

    if (operation.HTTPStatusCode != 204) {
        [operation deserializeJSONResponseData];
        localError = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld: %@",
                    (long) operation.HTTPStatusCode,
                    (id) operation.responseData] }];
        return localError;
    }

    return nil;
}

@end
