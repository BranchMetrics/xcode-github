//
//  XGXcodeBot.m
//  xcode-github
//
//  Created by Edward on 2/28/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "XGXcodeBot.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"

#pragma mark NSDateFormatter (xcodegithub)

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
@property (readwrite) NSString*_Nullable result;
@property (readwrite) NSString*_Nullable currentStep;
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
    _integrationID = _dictionary[@"_id"];
    _integrationNumber = _dictionary[@"number"];
    _result = _dictionary[@"result"];
    _currentStep = _dictionary[@"currentStep"];

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

@end

#pragma mark - XGXcodeBot

@implementation XGXcodeBot

- (instancetype) init {
    return [self initWithServerName:nil dictionary:nil];
}

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
    }
    @catch(id error) {
        BNCLogError(@"Can't retrieve source control URL: %@", error);
    }
    return self;
}

+ (NSString*) botNameFromPRNumber:(NSString *)number title:(NSString *)title {
    if (!number) number = @"0";
    if (!title) title = @"no-title";
    NSString *newTitle =
        [[[[[title lowercaseString]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            stringByReplacingOccurrencesOfString:@" " withString:@"-"]
            stringByReplacingOccurrencesOfString:@"\n" withString:@"-"]
            stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    newTitle = [NSString stringWithFormat:@"xcode-github PR#%@ %@", number, newTitle];
    return newTitle;
}

+ (NSString*_Nullable) gitHubPRNameFromString:(NSString*_Nullable)string {
    if ([string hasPrefix:@"xcode-github PR#"])
        return [string substringFromIndex:13];
    return nil;
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
    if (error) *error = localError;
    return bots;
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
                status = [[XGXcodeBotStatus alloc] init];
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

- (NSError*_Nullable) removeFromServer {
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
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (operation.error) return operation.error;

    if (operation.HTTPStatusCode != 200) {
        localError = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
        return localError;
    }

    return nil;
}

- (NSString*_Nullable) pullRequestNumber {
    NSString*const kBotPrefixString = @"xcode-github PR#";
    if ([self.name hasPrefix:kBotPrefixString] && self.name.length > kBotPrefixString.length) {
        NSString *number = nil;
        NSScanner *scanner = [NSScanner scannerWithString:self.name];
        [scanner scanString:kBotPrefixString intoString:nil];
        [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&number];
        return number;
    }
    return nil;
}

+ (XGXcodeBot*_Nullable) duplicateBot:(XGXcodeBot*_Nonnull)templateBot
                          withNewName:(NSString*_Nonnull)newBotName
                     gitHubBranchName:(NSString*_Nonnull)branchName
                                error:(NSError*__autoreleasing _Nullable*_Nullable)error {
    XGXcodeBot *bot = nil;
    NSError *localError = nil;
    {
        NSString *string =
            [NSString stringWithFormat:@"https://%@:20343/api/bots/%@/duplicate",
                templateBot.serverName,
                templateBot.botID];
        NSURL *URL = [NSURL URLWithString:string];
        if (!URL) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadURL
                    userInfo:@{
                        NSLocalizedDescriptionKey:
                            [NSString stringWithFormat:@"Bad server name '%@'.", templateBot.serverName]
                    }
                ];
            BNCLogError(@"Bad server name '%@'.", templateBot.serverName);
            goto exit;
        }

        NSMutableDictionary *dictionary = (__bridge_transfer NSMutableDictionary*)
            CFPropertyListCreateDeepCopy(
                kCFAllocatorDefault,
                (CFDictionaryRef)templateBot.dictionary,
                kCFPropertyListMutableContainers
        );
        dictionary[@"configuration"]
            [@"sourceControlBlueprint"]
            [@"DVTSourceControlWorkspaceBlueprintLocationsKey"]
            [templateBot.sourceControlWorkspaceBlueprintLocationsID]
            [@"DVTSourceControlBranchIdentifierKey"] =
                branchName;
        dictionary[@"integration_counter"] = nil;
        dictionary[@"lastRevisionBlueprint"] = nil;
        dictionary[@"name"] = newBotName;

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
            bot = [[XGXcodeBot alloc] initWithServerName:templateBot.serverName dictionary:d];
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
