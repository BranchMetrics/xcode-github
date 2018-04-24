//
//  XGGitHubPullRequest.h
//  xcode-github
//
//  Created by Edward on 2/28/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XGPullRequestStatus) {
    XGPullRequestStatusError,
    XGPullRequestStatusFailure,
    XGPullRequestStatusPending,
    XGPullRequestStatusSuccess,
 };

@interface XGGitHubPullRequest : NSObject
@property (strong, readonly) NSString*_Nullable repoOwner;
@property (strong, readonly) NSString*_Nullable repoName;
@property (strong, readonly) NSString*_Nullable branch;
@property (strong, readonly) NSString*_Nullable number;
@property (strong, readonly) NSString*_Nullable title;
@property (strong, readonly) NSString*_Nullable body;
@property (strong, readonly) NSString*_Nullable state;
@property (strong, readonly) NSDictionary*_Nullable dictionary;
@property (strong, readonly) NSString*_Nullable sha;
@property (strong, readonly) NSString*_Nullable githubPRURL;

- (instancetype _Nonnull) initWithDictionary:(NSDictionary*_Nullable)dictionary NS_DESIGNATED_INITIALIZER;

- (NSError*_Nullable) setStatus:(XGPullRequestStatus)status
                        message:(NSString*)message
                      statusURL:(NSURL*_Nullable)statusURL
                      authToken:(NSString*_Nullable)authToken;

+ (NSDictionary<NSString*, XGGitHubPullRequest*>*_Nullable)
    pullsRequestsForRepository:(NSString*_Nonnull)sourceControlRepository
    authToken:(NSString*_Nonnull)authToken
    error:(NSError*_Nullable __autoreleasing *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
