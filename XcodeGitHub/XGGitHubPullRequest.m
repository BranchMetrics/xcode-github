/**
 @file          XGGitHubPullRequest.m
 @package       xcode-github
 @brief         A class for working with GitHub PR statuses.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGGitHubPullRequest.h"
#import "XGUtility.h"
#import "BNCLog.h"
#import "BNCNetworkService.h"

NSString*_Nonnull NSStringFromXGPullRequestStatus(XGPullRequestStatus status) {
    NSArray<NSString*>*statusStrings = @[
        @"XGPullRequestStatusError",
        @"XGPullRequestStatusFailure",
        @"XGPullRequestStatusPending",
        @"XGPullRequestStatusSuccess",
    ];
    if (status >= XGPullRequestStatusError && status <= XGPullRequestStatusSuccess)
        return statusStrings[status];
    return [NSString stringWithFormat:@"< Unknown status '%ld' >", (long) status];
}

#pragma mark - XGGitHubPullRequestStatus

@interface XGGitHubPullRequestStatus ()
@property (strong) NSDictionary*dictionary;
@end

@implementation XGGitHubPullRequestStatus

- (instancetype) initWithDictionary:(NSDictionary*)dictionary_ {
    self = [super init];
    if (!self) return self;
    self.dictionary = dictionary_;
    return self;
}

- (XGPullRequestStatus) status {
    NSDictionary*d = @{
        @"error":   @(XGPullRequestStatusError),
        @"failure": @(XGPullRequestStatusFailure),
        @"pending": @(XGPullRequestStatusPending),
        @"success": @(XGPullRequestStatusSuccess)
    };
    NSString*status = self.dictionary[@"state"];
    if (status) {
        NSNumber*n = d[status];
        if (n != nil) return n.integerValue;
    }
    return XGPullRequestStatusError;
}

- (NSString*_Nullable) message {
    return self.dictionary[@"description"];
}

- (NSDate*_Nullable) updateDate {
    NSString*s = self.dictionary[@"updated_at"];
    if (!s) return nil;
    NSDateFormatter *dateFormatter = [NSDateFormatter dateFormatter8601];
    return [dateFormatter dateFromString:s];
}

@end

#pragma mark - XGGitHubPullRequest

@interface XGGitHubPullRequest ()
@property (strong) NSString*_Nullable authToken;
@end

@implementation XGGitHubPullRequest

- (instancetype) init {
    return [self initWithDictionary:nil];
}

- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) return self;

    _dictionary = dictionary;
    _title = _dictionary[@"title"];
    _body = _dictionary[@"body"];
    _branch = _dictionary[@"head"][@"ref"];
    _number = _dictionary[@"number"];
    if (![_number isKindOfClass:NSString.class]) _number = _number.description;
    _state = _dictionary[@"state"];

    NSString* fullname = _dictionary[@"head"][@"repo"][@"full_name"];
    NSRange range = [fullname rangeOfString:@"/"];
    if (range.location != NSNotFound) {
        _repoOwner = [fullname substringToIndex:range.location];
        NSInteger index = range.location + range.length;
        if (index < fullname.length) _repoName = [fullname substringFromIndex:index];
    }
    _headSHA = _dictionary[@"head"][@"sha"];
    _baseSHA = _dictionary[@"base"][@"sha"];
    _githubPRURL = _dictionary[@"url"];
    return self;
}

+ (NSDictionary<NSString*, XGGitHubPullRequest*>*_Nullable)
    pullsRequestsForRepository:(NSString*_Nonnull)sourceControlRepository
    authToken:(NSString*_Nonnull)authToken
    error:(NSError*_Nullable __autoreleasing *_Nullable)error {

    NSError *localError = nil;
    NSMutableDictionary<NSString*, XGGitHubPullRequest*>* prs = nil;

    {
        NSString *repo = nil;
        NSRange range = [sourceControlRepository rangeOfString:@":"];
        range.location++;
        range.length = sourceControlRepository.length - range.location - 4;
        if ([sourceControlRepository hasSuffix:@".git"] &&
            range.location > 0 && range.length > 0) {
            repo = [sourceControlRepository substringWithRange:range];
        }

        if (![sourceControlRepository hasPrefix:@"github.com:"] || !repo) {
            NSString *s =
                [NSString stringWithFormat:@"Target reposity '%@' is not a github repository.",
                    sourceControlRepository];
            localError = [NSError errorWithDomain:NSNetServicesErrorDomain code:NSURLErrorCannotFindHost
                userInfo:@{ NSLocalizedDescriptionKey: s }];
            goto exit;
        }

        NSString *serverURLString =
            [NSString stringWithFormat:
                @"https://api.github.com/repos/%@/pulls?state=open&sort=created&direction=desc",
                    repo];

        NSURL *serverURL = [NSURL URLWithString:serverURLString];
        if (!serverURL) {
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain code:NSURLErrorBadURL userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Bad URL '%@'.", serverURL]
                }];
            BNCLogError(@"Bad URL '%@'.", serverURL);
            goto exit;
        }

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        BNCNetworkOperation *operation =
            [[BNCNetworkService shared]
                getOperationWithURL:serverURL completion:^(BNCNetworkOperation *operation) {
                dispatch_semaphore_signal(semaphore);
            }];
        [operation.request addValue:@"application/vnd.github.v3+json" forHTTPHeaderField:@"Accept"];
        if (authToken.length > 0) {
            NSString *token = [NSString stringWithFormat:@"token %@", authToken];
            [operation.request addValue:token forHTTPHeaderField:@"Authorization"];
        }
        [operation start];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        if (operation.error) {
            NSString *message = operation.stringFromResponseData;
            if (message.length) BNCLogError(@"From GitHub: %@.", message);
            localError = operation.error;
            goto exit;
        }
        [operation deserializeJSONResponseData];
        if (operation.error) {
            NSString *message = operation.stringFromResponseData;
            if (message.length) BNCLogError(@"From GitHub: %@.", message);
            localError = operation.error;
            goto exit;
        }
        if (operation.HTTPStatusCode != 200) {
            NSString*message = nil;
            NSDictionary*dictionary = (id) operation.responseData;
            if ([dictionary isKindOfClass:NSDictionary.class]) {
                message = dictionary[@"message"];
            }
            if (!message)
                message = [NSString stringWithFormat:@"GitHub response code %ld.", operation.HTTPStatusCode];
            localError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:@{
                NSLocalizedDescriptionKey: message
            }];
            goto exit;
        }
        NSArray *array = (id) operation.responseData;
        if (![array isKindOfClass:NSArray.class]) {
            NSString *message = operation.stringFromResponseData;
            if (message.length) BNCLogError(@"From GitHub: %@.", message);
            localError =
                [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSURLErrorBadServerResponse
                    userInfo:@{ NSLocalizedDescriptionKey: @"Expected an array." }];
            goto exit;
        }

        prs = [NSMutableDictionary new];
        for (NSDictionary *d in array) {
            XGGitHubPullRequest *pr = [[XGGitHubPullRequest alloc] initWithDictionary:d];
            if (pr && pr.number) {
                pr.authToken = authToken;
                prs[pr.number] = pr;
            }
        }
    }

exit:
    if (error) *error = localError;
    return prs;
}

+ (NSString*) stringFromStatus:(XGPullRequestStatus)status {
    status = MAX(XGPullRequestStatusError, MIN(XGPullRequestStatusSuccess, status));
    NSArray*a =  @[
        @"error",
        @"failure",
        @"pending",
        @"success",
    ];
    return a[status];
}

- (NSArray<XGGitHubPullRequestStatus*>*_Nullable) statusesWithError:
        (NSError*_Nullable __autoreleasing *_Nullable)error_ {
    NSError*error = nil;
    NSMutableArray<XGGitHubPullRequestStatus*>*results = nil;

    {
    NSString* string = [NSString stringWithFormat:
        @"https://api.github.com/repos/%@/%@/commits/%@/statuses",
            self.repoOwner, self.repoName, self.headSHA];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        error =
            [NSError errorWithDomain:NSNetServicesErrorDomain code:NSURLErrorBadURL userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Bad URL '%@'.", URL]
            }];
        BNCLogError(@"Bad URL '%@'.", URL);
        goto exit;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            getOperationWithURL:URL
            completion:^(BNCNetworkOperation *operation) {
            dispatch_semaphore_signal(semaphore);
        }];
    [operation.request addValue:@"application/vnd.github.v3+json" forHTTPHeaderField:@"Accept"];
    if (self.authToken.length > 0) {
        NSString *token = [NSString stringWithFormat:@"token %@", self.authToken];
        [operation.request addValue:token forHTTPHeaderField:@"Authorization"];
    }
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (operation.error) {
        NSString *message = operation.stringFromResponseData;
        if (message.length) BNCLogError(@"From GitHub: %@.", message);
        error = operation.error;
        goto exit;
    }
    [operation deserializeJSONResponseData];
    if (operation.error) {
        NSString *message = operation.stringFromResponseData;
        if (message.length) BNCLogError(@"From GitHub: %@.", message);
        error = operation.error;
        goto exit;
    }
    if (operation.HTTPStatusCode != 200) {
        error = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
        BNCLogError(@"Response was: %@.", [operation stringFromResponseData]);
        goto exit;
    }
    NSArray*array = (NSArray*) operation.responseData;
    if (![array isKindOfClass:NSArray.class]) {
        error = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"Expecting an array: %@.", NSStringFromClass(array.class)]}];
        BNCLogError(@"Response was: %@.", [operation stringFromResponseData]);
        goto exit;
    }
    results = [NSMutableArray new];
    for (NSDictionary*d in array) {
        if (d.count > 0) {
            XGGitHubPullRequestStatus*status = [[XGGitHubPullRequestStatus alloc] initWithDictionary:d];
            if (status) [results addObject:status];
        }
    }

    }
exit:
    if (error_) *error_ = error;
    return results;
}

- (NSError*_Nullable) setStatus:(XGPullRequestStatus)status
                        message:(NSString*)message
                      statusURL:(NSURL*)statusURL {
    NSError *error = nil;
    NSString* string = [NSString stringWithFormat:
        @"https://api.github.com/repos/%@/%@/statuses/%@",
            self.repoOwner, self.repoName, self.headSHA];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        error =
            [NSError errorWithDomain:NSNetServicesErrorDomain code:NSURLErrorBadURL userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Bad URL '%@'.", URL]
            }];
        BNCLogError(@"Bad URL '%@'.", URL);
        return error;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"state"] = [self.class stringFromStatus:status];
    dictionary[@"context"] = @"continuous-integration/xcode-github";
    if (statusURL) dictionary[@"target_url"] = statusURL;
    if (message.length) dictionary[@"description"] = message;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            postOperationWithURL:URL
            JSONData:dictionary
            completion:^(BNCNetworkOperation *operation) {
            dispatch_semaphore_signal(semaphore);
        }];
    [operation.request addValue:@"application/vnd.github.v3+json" forHTTPHeaderField:@"Accept"];
    if (self.authToken.length > 0) {
        NSString *token = [NSString stringWithFormat:@"token %@", self.authToken];
        [operation.request addValue:token forHTTPHeaderField:@"Authorization"];
    }
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (operation.error) {
        NSString *message = operation.stringFromResponseData;
        if (message.length) BNCLogError(@"From GitHub: %@.", message);
        return operation.error;
    }
    [operation deserializeJSONResponseData];
    if (operation.error) {
        NSString *message = operation.stringFromResponseData;
        if (message.length) BNCLogError(@"From GitHub: %@.", message);
        return operation.error;
    }
    if (operation.HTTPStatusCode != 201) {
        error = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
        BNCLogError(
            @"Can't access GitHub status. Is write access enabled and the token set?\nResponse was: %@.",
            [operation stringFromResponseData]
        );
        return error;
    }
    return error;
}

- (NSError*_Nullable) addComment:(NSString*)comment {
    NSError *error = nil;
    NSString* string = [NSString stringWithFormat:
        @"https://api.github.com/repos/%@/%@/commits/%@/comments",
            self.repoOwner, self.repoName, self.headSHA];
    NSURL *URL = [NSURL URLWithString:string];
    if (!URL) {
        error =
            [NSError errorWithDomain:NSNetServicesErrorDomain code:NSURLErrorBadURL userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Bad URL '%@'.", URL]
            }];
        BNCLogError(@"Bad URL '%@'.", URL);
        return error;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"body"] = comment;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            postOperationWithURL:URL
            JSONData:dictionary
            completion:^(BNCNetworkOperation *operation) {
            dispatch_semaphore_signal(semaphore);
        }];
    [operation.request addValue:@"application/vnd.github.v3.raw+json" forHTTPHeaderField:@"Accept"];
    if (self.authToken.length > 0) {
        NSString *token = [NSString stringWithFormat:@"token %@", self.authToken];
        [operation.request addValue:token forHTTPHeaderField:@"Authorization"];
    }
    [operation start];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (operation.error) {
        NSString *message = operation.stringFromResponseData;
        if (message.length) BNCLogError(@"From GitHub: %@.", message);
        return operation.error;
    }
    [operation deserializeJSONResponseData];
    if (operation.error) {
        NSString *message = operation.stringFromResponseData;
        if (message.length) BNCLogError(@"From GitHub: %@.", message);
        return operation.error;
    }
    if (operation.HTTPStatusCode != 201) {
        error = [NSError errorWithDomain:NSNetServicesErrorDomain
            code:NSNetServicesInvalidError userInfo:@{NSLocalizedDescriptionKey:
                [NSString stringWithFormat:@"HTTP Status %ld", (long) operation.HTTPStatusCode]}];
        BNCLogError(@"Response was: %@.", [operation stringFromResponseData]);
        return error;
    }

    return error;
}

@end
