/**
 @file          XGANetworkServiceBrowser.h
 @package       xcode-github-app
 @brief         Browses for Bonjour (mDNS) services.

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark XGANetworkServiceHost

@interface XGANetworkServiceHost : NSObject
- (instancetype) init NS_UNAVAILABLE;
@property (strong, readonly) NSError*_Nullable error;
@property (strong, readonly) NSArray<NSString*>*names;
@property (strong, readonly) NSArray<NSString*>*addresses;
@end

#pragma mark - XGANetworkServiceBrowser

@protocol XGANetworkServiceBrowserDelegate;

// For xcode servers, the domain is "" and service "_xcs2p._tcp."

@interface XGANetworkServiceBrowser : NSObject
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithDomain:(NSString*)domain service:(NSString*)service NS_DESIGNATED_INITIALIZER;
- (void) startDiscovery;
- (void) stopDiscovery;

@property (strong, readonly) NSString*domain;
@property (strong, readonly) NSString*service;
@property (strong, readonly) NSArray<XGANetworkServiceHost*>*hosts;
@property (weak) id<XGANetworkServiceBrowserDelegate> delegate;
@end

#pragma mark - XGANetworkServiceBrowserDelegate

@protocol XGANetworkServiceBrowserDelegate <NSObject>

@optional
- (void) browser:(XGANetworkServiceBrowser*)browser discoveredHost:(XGANetworkServiceHost*)host;

@optional
- (void) browser:(XGANetworkServiceBrowser*)browser finishedWithError:(NSError*_Nullable)error;

@end

NS_ASSUME_NONNULL_END
