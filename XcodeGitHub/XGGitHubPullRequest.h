/**
 @file          XGGitHubPullRequest.h
 @package       xcode-github
 @brief         A class for working with GitHub PR statuses.

 @author        Edward Smith
 @date          February 28, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XGPullRequestStatus) {
    XGPullRequestStatusError = 0,
    XGPullRequestStatusFailure,
    XGPullRequestStatusPending,
    XGPullRequestStatusSuccess,
 };

FOUNDATION_EXPORT NSString*_Nonnull NSStringFromXGPullRequestStatus(XGPullRequestStatus status);

#pragma mark - XGGitHubPullRequestStatus

@interface XGGitHubPullRequestStatus : NSObject
- (instancetype) init NS_UNAVAILABLE;
+ (instancetype) new  NS_UNAVAILABLE;
@property (assign, readonly) XGPullRequestStatus status;
@property (strong, readonly) NSString*_Nullable message;
@property (strong, readonly) NSDate*_Nullable updateDate;
@end

#pragma mark - XGGitHubPullRequest

@interface XGGitHubPullRequest : NSObject
@property (strong, readonly) NSString*_Nullable repoOwner;
@property (strong, readonly) NSString*_Nullable repoName;
@property (strong, readonly) NSString*_Nullable branch;
@property (strong, readonly) NSString*_Nullable number;
@property (strong, readonly) NSString*_Nullable title;
@property (strong, readonly) NSString*_Nullable body;
@property (strong, readonly) NSString*_Nullable state;
@property (strong, readonly) NSDictionary*_Nullable dictionary;
@property (strong, readonly) NSString*_Nullable headSHA;
@property (strong, readonly) NSString*_Nullable baseSHA;
@property (strong, readonly) NSString*_Nullable githubPRURL;

+ (instancetype _Nonnull) new NS_UNAVAILABLE;
- (instancetype _Nonnull) init NS_UNAVAILABLE;

- (instancetype _Nonnull) initWithDictionary:(NSDictionary*_Nullable)dictionary NS_DESIGNATED_INITIALIZER;

- (NSArray<XGGitHubPullRequestStatus*>*_Nullable) statusesWithError:(NSError*_Nullable __autoreleasing *_Nullable)error;

- (NSError*_Nullable) setStatus:(XGPullRequestStatus)status
                        message:(NSString*)message
                      statusURL:(NSURL*_Nullable)statusURL;

- (NSError*_Nullable) addComment:(NSString*)comment;

+ (NSDictionary<NSString*, XGGitHubPullRequest*>*_Nullable)
    pullsRequestsForRepository:(NSString*_Nonnull)sourceControlRepository
    authToken:(NSString*_Nonnull)authToken
    error:(NSError*_Nullable __autoreleasing *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
