//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLTerminal;
@class YLTelnet;

@interface YLView : NSView {	
	int _fontWidth;
	int _fontHeight;
	
	NSImage *_backedImage;
	
	YLTerminal *_dataSource;
	YLTelnet *_telnet;
	
	BOOL _connected;
	
	NSTimer *_timer;
	int _x;
	int _y;
}


- (void) update;
- (void) drawSpecialSymbol: (unichar) ch forRow: (int) r column: (int) c leftAttribute: (attribute) attr1 rightAttribute: (attribute) attr2 ;

- (id)dataSource;
- (void)setDataSource:(id)value;
- (YLTelnet *)telnet;
- (void)setTelnet:(YLTelnet *)value;
- (BOOL)connected;
- (void)setConnected:(BOOL)value;

- (void) extendBottom ;
- (void) extendTop ;
- (void) clearScreen: (int) opt atRow: (int) r column: (int) c ;

- (void) drawStringForRow: (int) r context: (CGContextRef) myCGContext ;
- (void) updateBackgroundForRow: (int) r from: (int) start to: (int) end ;
@end
