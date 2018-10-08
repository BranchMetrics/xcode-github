/**
 @file          XGXcodeBot.m
 @package       xcode-github
 @brief         A class for working with Xcode bot statuses.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGXcodeBot.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"
#import "APFormattedString.h"

#pragma mark Helper Functions

NSString* XGDurationStringFromTimeInterval(NSTimeInterval timeInterval) {
    int seconds = (int) round(fabs(timeInterval));
    int minutes = seconds / 60;
    seconds = seconds % 60;
    int hours = minutes / 60;
    minutes = minutes % 60;

    NSMutableString *string = [NSMutableString new];
    if (hours == 1)
        [string appendString:@"one hour, "];
    else
    if (hours > 0)
        [string appendFormat:@"%d hours, ", hours];

    if (minutes == 1)
        [string appendString:@"one minute, "];
    else
    if (minutes > 0)
        [string appendFormat:@"%d minutes, ", minutes];

    if (seconds == 1)
        [string appendString:@"one second, "];
    else
    if (seconds > 0)
        [string appendFormat:@"%d seconds, ", seconds];

    if (string.length > 2)
        [string deleteCharactersInRange:NSMakeRange(string.length-2, 2)];
    else
        string = [NSMutableString stringWithString:@"zero seconds"];

    NSString *result = [NSString stringWithFormat:@"%@%@",
        [[string substringToIndex:1] uppercaseString],
        [string substringFromIndex:1]];

    return result;
}

#pragma mark - NSDateFormatter (xcodegithub)

@interface NSDateFormatter (xcodegithub)
+ (NSDateFormatter*_Nonnull) dateFormatter8601;
@end

@implementation NSDateFormatter (xcodegithub)

+ (NSDateFormatter*) dateFormatter8601 {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSX";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return formatter;
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

- (APFormattedString*) formattedDetailString {
    NSTimeInterval duration = [self.endedDate timeIntervalSinceDate:self.startedDate];
    NSString*durationString = XGDurationStringFromTimeInterval(duration);

    APFormattedString *apstring =
        [[[[APFormattedString
            boldText:@"Result of Integration %@", self.integrationNumber]
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

    if ([self.errorCount integerValue] == 0 &&
        [self.result isEqualToString:@"succeeded"]) {
        [apstring boldText:@"Perfect build! 👍"];

        if ([self.testsCount integerValue] > 0) {
            if ([self.codeCoveragePercentage doubleValue] > 0.0) {
                [[apstring
                    italicText:@"\nTest Coverage"]
                    plainText:@": %@%% (%@ tests).", self.codeCoveragePercentage, self.testsCount];
            } else {
                [apstring italicText:@"\nAll %@ tests passed.", self.testsCount];
            }
        }

        return apstring;
    }

    [apstring boldText:@"Failing state: %@.", self.summaryString];
    if ([self.tags containsObject:@"xcs-upgrade"]) {
        [apstring
            italicText:@"\nThe current configuration may not be supported by the Xcode upgrade."];
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

- (instancetype) initWithServerName:(NSString *)serverName dictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return self;

    _serverName = [serverName copy];
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
                substringWithRange:NSMakeRange(repoRange.location+1, self.sourceControlRepository.length - repoRange.location - 1)];
            if ([_repoName hasSuffix:@".git"]) {
                _repoName = [_repoName substringWithRange:NSMakeRange(0, _repoName.length-4)];
            }
            NSDictionary*locations = _dictionary[@"configuration"][@"sourceControlBlueprint"][@"DVTSourceControlWorkspaceBlueprintLocationsKey"];
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

+ (NSDictionary<NSString*, XGXcodeBot*>*_Nullable) botsForServer:(NSString*_Nonnull)xcodeServerName
        error:(NSError*__autoreleasing _Nullable*_Nullable)error {

    NSError *localError = nil;
    NSMutableDictionary<NSString*, XGXcodeBot*>* bots = nil;
    
    {
        NSString *serverURLString =
            [NSString stringWithFormat:@"https://%@:20343/api/bots", xcodeServerName];
        NSURL *serverURL = [NSURL URLWithString:serverURLString];
        if (!serverURL) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadURL
                    userInfo:@{
                        NSLocalizedDescriptionKey:
                            [NSString stringWithFormat:@"Bad server name '%@'.", xcodeServerName]
                    }
                ];
            BNCLogError(@"Bad server name '%@'.", xcodeServerName);
            goto exit;
        }

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                getOperationWithURL:serverURL completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
            }];
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
            XGXcodeBot *bot = [[XGXcodeBot alloc] initWithServerName:xcodeServerName dictionary:d];
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
                    self.serverName, self.botID];
        NSURL *statusURL = [NSURL URLWithString:statusString];

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                getOperationWithURL:statusURL completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
            }];
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
                status = [[XGXcodeBotStatus alloc] initWithServerName:self.serverName dictionary:a[0]];
            else {
                status = [[XGXcodeBotStatus alloc] initWithServerName:self.serverName dictionary:nil];
                status.botID = self.botID;
                status.botName = self.name;
                status.serverName = self.serverName;
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
    if (!status) status = [[XGXcodeBotStatus alloc] initWithServerName:self.serverName dictionary:nil];
    if (localError) status.error = localError;
    return status;
}

- (NSError*_Nullable) deleteBot {
    NSError *localError = nil;
    NSString *string = [NSString stringWithFormat:
        @"https://%@:20343/api/bots/%@", self.serverName, self.botID];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadURL
                userInfo:@{
                    NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"Bad server name '%@'.", self.serverName]
                }
            ];
        BNCLogError(@"Bad server name '%@'.", self.serverName);
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
        NSString *string =
            [NSString stringWithFormat:@"https://%@:20343/api/bots/%@/duplicate",
                self.serverName,
                self.botID];
        NSURL *URL = [NSURL URLWithString:string];
        if (!URL) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadURL
                    userInfo:@{
                        NSLocalizedDescriptionKey:
                            [NSString stringWithFormat:@"Bad server name '%@'.", self.serverName]
                    }
                ];
            BNCLogError(@"Bad server name '%@'.", self.serverName);
            goto exit;
        }

        NSMutableDictionary *dictionary = (__bridge_transfer NSMutableDictionary*)
            CFPropertyListCreateDeepCopy(
                kCFAllocatorDefault,
                (CFDictionaryRef)self.dictionary,
                kCFPropertyListMutableContainers
        );
        dictionary[@"configuration"]
            [@"sourceControlBlueprint"]
            [@"DVTSourceControlWorkspaceBlueprintLocationsKey"]
            [self.sourceControlWorkspaceBlueprintLocationsID]
            [@"DVTSourceControlBranchIdentifierKey"] =
                branchName;
        dictionary[@"configuration"][@"scheduleType"] = @2; // 2: On commit
        dictionary[@"integration_counter"] = nil;
        dictionary[@"lastRevisionBlueprint"] = nil;
        dictionary[@"name"] = newBotName;
        dictionary[@"templateBotName"] = self.name;
        dictionary[@"pullRequestNumber"] = pullRequestNumber;
        dictionary[@"pullRequestTitle"] = pullRequestTitle;

        NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&localError];
        if (localError) goto exit;

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                postOperationWithURL:URL
                contentType:@"application/json"
                data:data
                completion:^(BNCNetworkOperation *operation) {
                    dispatch_semaphore_signal(semaphore);
            }];
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
        if ([d isKindOfClass:NSDictionary.class]) {
            bot = [[XGXcodeBot alloc] initWithServerName:self.serverName dictionary:d];
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
        @"https://%@:20343/api/bots/%@/integrations", self.serverName, self.botID];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        localError =
            [NSError errorWithDomain:NSNetServicesErrorDomain
                code:NSURLErrorBadURL
                userInfo:@{
                    NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"Bad server name '%@'.", self.serverName]
                }
            ];
        BNCLogError(@"Bad server name '%@'.", self.serverName);
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

@end