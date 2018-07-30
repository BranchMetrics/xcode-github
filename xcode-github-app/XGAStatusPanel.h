//
//  XGAStatusPanel.h
//  xcode-github-app
//
//  Created by Edward on 7/29/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "APPArrowPanel.h"

@interface XGAStatusPanel : APPArrowPanel
+ (instancetype) loadPanel;
@property (strong) IBOutlet NSTextField*summaryTextField;
@property (strong) IBOutlet NSTextField*detailTextField;
@property (strong) IBOutlet NSImageView*imageView;
- (void) show;
- (void) dismiss;
@end
