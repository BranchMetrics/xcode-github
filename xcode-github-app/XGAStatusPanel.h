/**
 @file          XGAStatusPanel.h
 @package       xcode-github-app
 @brief         A status heads-up window for the status and log windows.

 @author        Edward Smith
 @date          July 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "APPArrowPanel.h"

@interface XGAStatusPanel : APPArrowPanel
@property (strong) IBOutlet NSTextField*titleTextField;
@property (strong) IBOutlet NSTextField*detailTextField;
@property (strong) IBOutlet NSImageView*imageView;
@end
