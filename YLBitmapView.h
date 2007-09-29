//
//  YLView.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@class YLTerminal;
@class YLTelnet;

@interface YLBitmapView : NSView {
	NSColor *_bgColor;
	NSColor *_fgColor;
	
	int _fontWidth;
	int _fontHeight;
	
	NSBitmapImageRep *_imgRep;
	unsigned int *_mem;
	
	YLTerminal *_dataSource;
	YLTelnet *_telnet;
}

- (void) updateRow: (int) r from: (int) start to: (int) end ;
- (void)drawChar: (unichar) ch atPoint: (NSPoint) origin withAttribute: (attribute) attr ;
- (id)dataSource;
- (void)setDataSource:(id)value;
- (YLTelnet *)telnet;
- (void)setTelnet:(YLTelnet *)value;


@end
