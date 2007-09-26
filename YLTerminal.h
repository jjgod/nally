//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <deque>
#import "CommonType.h"

@interface YLTerminal : NSObject {	
	unsigned int _row;
	unsigned int _column;
	unsigned int _cursorX;
	unsigned int _cursorY;
	unsigned int _offset;
	
	int _savedCursorX;
	int _savedCursorY;

	int _fgColor;
	int _bgColor;
	BOOL _bold;
	BOOL _underline;
	BOOL _blink;
	BOOL _reverse;
	
	cell *_grid;
	char *_dirty;
	
	enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL } _state;

	std::deque<unsigned char> *_csBuf;
	std::deque<int> *_csArg;
	unsigned int _csTemp;
	id _delegate;
}

- (void) feedData: (NSData *) data ;
- (void) feedBytes: (const unsigned char *) bytes length: (int) len ;

- (BOOL) isDirtyAtRow: (int) r column:(int) c;
- (attribute) attrAtRow: (int) r column: (int) c ;
- (NSColor *) fgColorAtRow: (int) r column: (int) c;
- (NSColor *) bgColorAtRow: (int) r column: (int) c;
- (BOOL) boldAtRow:(int) r column:(int) c ;
- (unichar) charAtRow: (int) r column: (int) c;
- (cell *) cellsOfRow: (int) r ;
- (void) updateDoubleByteStateForRow: (int) r ;
- (int) isDoubleByteAtRow: (int) r column:(int) c;
- (void) setAllDirty ;
- (void) setDirty: (BOOL) d atRow: (int) r column: (int) c ;

- (void) setDelegate: (id) d;
- (id) delegate;

@end
