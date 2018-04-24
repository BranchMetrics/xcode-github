/**
 @file          BNCNetworkOperation+Image.h
 @package       Branch-SDK
 @brief         Decode an image after a network operation.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

@import Foundation;
#import "BNCNetworkService.h"

@interface BNCNetworkOperation (Image)
- (void) deserializeImageResponseData;
@end
