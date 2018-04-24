/**
 @file          BNCNetworkOperation+Image.h
 @package       Branch-SDK
 @brief         Decode an image after a network operation.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCNetworkOperation+Image.h"

@implementation BNCNetworkOperation (Image)

- (void) deserializeImageResponseData {
    @synchronized (self) {
        UIImage *image = nil;
        if ([self.responseData isKindOfClass:[UIImage class]]) {
            image = (UIImage*) self.responseData;
        } else if ([self.responseData isKindOfClass:[NSData class]]) {
            @try {
                image = [UIImage imageWithData:(NSData*)self.responseData];
            }
            @catch (id exception) {
                image = nil;
            }
        } else {
            BNCLogWarning(@"Unknown response class '%@'.", [self.responseData class]);
        }
        if (image) {
            self.responseData = image;
        } else {
            self.error =
                [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                    userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode image data."}];
        }
    }
}

@end
