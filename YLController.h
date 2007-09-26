//
//  YLController.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLView.h"

@class YLTerminal;

@interface YLController : NSObject {
	IBOutlet id _telnetView;
	NSTimer *_updateViewTimer;
	YLTerminal *_terminal;
}

@end
