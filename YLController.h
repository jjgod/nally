//
//  YLController.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLView.h"
#import <PSMTabBarControl/PSMTabBarControl.h>

@class YLTerminal;

@interface YLController : NSObject {
	IBOutlet id _telnetView;
	IBOutlet id _addressBar;
    IBOutlet PSMTabBarControl *_tab;
}

- (IBAction)connect:(id )sender;
- (IBAction)openLocation:(id )sender;

@end
