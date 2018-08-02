//
//  XGAStatusPanel.h
//  xcode-github-app
//
//  Created by Edward on 7/29/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "APPArrowPanel.h"

@interface XGAStatusPanel : APPArrowPanel
@property (strong) IBOutlet NSTextField*titleTextField;
@property (strong) IBOutlet NSTextField*detailTextField;
@property (strong) IBOutlet NSImageView*imageView;
@end
