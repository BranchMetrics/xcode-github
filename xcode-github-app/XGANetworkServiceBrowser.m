/**
 @file          XGANetworkServiceBrowser.m
 @package       xcode-github-app
 @brief         Browses for Bonjour (mDNS) services.

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGANetworkServiceBrowser.h"
#import <XcodeGitHub/XcodeGitHub.h>
#import <arpa/inet.h>

// https://superuser.com/questions/443514/how-to-get-shared-computers-ip-addresses-in-os-x-10-7?answertab=votes#tab-top
// dns-sd -L 'MacBook Pro (2)' _xcs2p._tcp local

@interface XGANetworkServiceHost () <NSNetServiceDelegate>
- (instancetype)   initWithService:(NSNetService*)service NS_DESIGNATED_INITIALIZER;
@property (strong) NSNetService*service;
@property (strong) NSArray<NSString*>*names;
@property (strong) NSArray<NSString*>*addresses;
@property (copy)   void (^completion)(XGANetworkServiceHost*serviceHost);
@end

@implementation XGANetworkServiceHost

- (instancetype) initWithService:(NSNetService *)service_ {
    self = [super init];
    if (!self) return self;
    self.service = service_;
    return self;
}

- (void) lookupWithCompletion:(void (^)(XGANetworkServiceHost*serviceHost))completion_ {
    self.service.delegate = self;
    [self.service resolveWithTimeout:7.0];
    self.completion = completion_;
}

#pragma mark NSNetService Delegate

// Sent when addresses are resolved
- (void)netServiceDidResolveAddress:(NSNetService *)service {
    BNCLogDebug(@"Did resolve %@ (%ld).", service.name, (long) service.addresses.count);
}

- (void)netService:(NSNetService *)netService
     didNotResolve:(NSDictionary *)errorDict {
    BNCLogDebug(@"Can't resolve %@: %@.", netService, errorDict);
//    self.error = [NSError errorWithDomain:NSNetworkDomain code:-1 userInfo:errorDict];
}

- (void)netServiceDidStop:(NSNetService *)service {
    @synchronized (self) {
        BNCLogDebug(@"Netservice stop %@.", service.name);
        __auto_type addresses = [NSMutableSet new];
        union {
            struct  sockaddr     sockaddr;
            struct  sockaddr_in  sockaddr_in;
            struct  sockaddr_in6 sockaddr_in6;
            uint8_t bytes[SOCK_MAXADDRLEN];
        } address;
        char string[512];
        for (NSData*d in service.addresses) {
            if (!d.bytes) continue;
            memcpy(&address, d.bytes, MIN(sizeof(address), d.length));
            void*a_ptr = NULL;
            int inet_type = address.sockaddr.sa_family;
            switch (inet_type) {
                case AF_INET:   a_ptr = &address.sockaddr_in.sin_addr;   break;
                case AF_INET6:  a_ptr = &address.sockaddr_in6.sin6_addr; break;
                default: continue;
            }
            const char*p = inet_ntop(inet_type, a_ptr, string, sizeof(string));
            if (p) {
                [addresses addObject:[NSString stringWithUTF8String:p]];
            } else {
                int err = errno;
                char*s = strerror(err);
                if (!s) s = "Unknown";
                BNCLogError(@"Can't resolve address (%d): %s.", err, s);
            }
        }
        self.addresses = addresses.allObjects;
        __auto_type names = [NSMutableSet set];
        for (NSString*a in self.addresses) {
            __auto_type host = [NSHost hostWithAddress:a];
            [names addObjectsFromArray:[host names]];
        }
        self.names = names.allObjects;
        if (self.completion)
            self.completion(self);
    }
}

@end

#pragma mark - XGANetworkServiceBrowser

@interface XGANetworkServiceBrowser () <NSNetServiceBrowserDelegate>
@property (strong) NSError*error;
@property (strong) NSNetServiceBrowser*networkBrowser;
@property (readwrite) NSArray*hosts;
@property (strong) NSMutableArray<XGANetworkServiceHost*>*resolvingHosts;
@property (strong) NSMutableArray<XGANetworkServiceHost*>*resolvedHosts;
@end

@implementation XGANetworkServiceBrowser

- (instancetype) initWithDomain:(NSString*)domain service:(NSString*)service {
    self = [super init];
    if (!self) return self;
    self->_domain = (domain) ?: @"";
    self->_service = (service) ?: @"";
    self->_hosts = [NSArray new];
    self->_resolvingHosts = [NSMutableArray new];
    return self;
}

- (void) startDiscovery {
    BNCLogMethodName();
    self.error = nil;
    self.resolvingHosts = [NSMutableArray new];
    self.resolvedHosts = [NSMutableArray new];
    self.networkBrowser.delegate = nil;
    self.networkBrowser = [[NSNetServiceBrowser alloc] init];
    self.networkBrowser.delegate = self;
    self.networkBrowser.includesPeerToPeer = YES;
    [self.networkBrowser searchForServicesOfType:self.service inDomain:self.domain];
}

- (void) stopDiscovery {
    BNCLogMethodName();
    [self.networkBrowser stop];
    self.networkBrowser.delegate = nil;
    if ([self.delegate respondsToSelector:@selector(browser:finishedWithError:)]) {
        [self.delegate browser:self finishedWithError:self.error];
    }
}

#pragma mark - NSNetServiceBrowser Delegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict {
    BNCLogError(@"NSNetServiceBrowser error: %@.", errorDict);
//    NSString*errorDomain = errorDict[@"NSNetServiceBrowserErrorDomain"];
//    if (!errorDomain) errorDomain = NSNetServicesErrorDomain;
    NSNumber*code = errorDict[@"NSNetServiceBrowserErrorCode"];
    if (!code) code = [NSNumber numberWithInteger:-1];
    self.error = [NSError errorWithDomain:NSNetServicesErrorDomain code:code.integerValue userInfo:nil];
    if ([self.delegate respondsToSelector:@selector(browser:finishedWithError:)]) {
        [self.delegate browser:self finishedWithError:self.error];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)service
               moreComing:(BOOL)moreComing {
    BNCLogMethodName();
    XGANetworkServiceHost*host = [[XGANetworkServiceHost alloc] initWithService:service];
    if (!host) return;
    [self.resolvingHosts addObject:host];
    [host lookupWithCompletion:^(XGANetworkServiceHost *serviceHost) {
        if (serviceHost && !serviceHost.error) {
            [self.resolvedHosts addObject:serviceHost];
            if ([self.delegate respondsToSelector:@selector(browser:discoveredHost:)]) {
                [self.delegate browser:self discoveredHost:serviceHost];
            }
        }
        [self.resolvingHosts removeObject:serviceHost];
        if (!moreComing) {
            self.hosts = self.resolvedHosts;
            self.resolvedHosts = nil;
            if ([self.delegate respondsToSelector:@selector(browser:finishedWithError:)]) {
                [self.delegate browser:self finishedWithError:self.error];
            }
         }
    }];
}

@end
