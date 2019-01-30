/**
 @file          BNCNetworkService.h
 @package       Branch-SDK
 @brief         Basic Networking Services

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark BNCNetworkOperation

@interface BNCNetworkOperation : NSObject
@property (readonly) NSURLSessionTaskState  sessionState;
@property (readonly) NSMutableURLRequest*_Nullable request;
@property (readonly) NSInteger              HTTPStatusCode;
@property (readonly) NSError*_Nullable      error;
@property (readonly) NSDate*_Nullable       dateStart;
@property (readonly) NSDate*_Nullable       dateFinish;
@property (readonly) id<NSObject>           responseData;

- (void) start;
- (void) cancel;

- (void) deserializeJSONResponseData;
- (NSString*_Nullable) stringFromResponseData;
- (void) setUser:(NSString*)user password:(NSString*)password;
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService : NSObject
+ (BNCNetworkService*) shared;

- (BNCNetworkOperation*) getOperationWithURL:(NSURL *)URL
                        completion:(void (^)(BNCNetworkOperation*operation))completion;

- (BNCNetworkOperation*) postOperationWithURL:(NSURL *)URL
                        contentType:(NSString*)contentType
                               data:(NSData*_Nullable)data
                         completion:(void (^)(BNCNetworkOperation*operation))completion;

- (BNCNetworkOperation*) postOperationWithURL:(NSURL *)URL
                                     JSONData:(id _Nullable)dictionaryOrArray
                                   completion:(void (^)(BNCNetworkOperation*operation))completion;

- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*)publicKeys;

/// An array of host domains that we will allow with a self-signed SSL cert.
@property (strong) NSMutableSet<NSString*>*_Nullable anySSLCertHosts;

/// Allow self-signed certs from any host. Trumps `anySSLCertHosts`.
@property (assign) BOOL allowAnySSLCert;
@end

NS_ASSUME_NONNULL_END
