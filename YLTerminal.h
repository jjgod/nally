//
//  YLTerminal.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <deque>
#import "CommonType.h"
#import "YLView.h"

@interface YLTerminal : NSObject {	
@public
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
	
	cell **_grid;
	char *_dirty;
	
	enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL } _state;
    
    YLEncoding _encoding;

	std::deque<unsigned char> *_csBuf;
	std::deque<int> *_csArg;
	unsigned int _csTemp;
	YLView *_delegate;
    
    int _scrollBeginRow;
    int _scrollEndRow;
}

- (void) feedData: (NSData *) data connection: (id) connection;
- (void) feedBytes: (const unsigned char *) bytes length: (int) len connection: (id) connection;
- (void) startConnection ;
- (void) closeConnection ;

- (void) clearRow: (int) r ;
- (void) clearRow: (int) r fromStart: (int) s toEnd: (int) e ;

- (BOOL) isDirtyAtRow: (int) r column:(int) c;
- (attribute) attrAtRow: (int) r column: (int) c ;

- (NSString *) stringFromIndex: (int) begin length: (int) length ;

- (cell *) cellsOfRow: (int) r ;
- (void) updateURLStateForRow: (int) r ;
- (void) updateDoubleByteStateForRow: (int) r ;
- (void) setAllDirty ;
- (void) setDirty: (BOOL) d atRow: (int) r column: (int) c ;
- (void) setDirtyForRow: (int) r ;

- (void) setDelegate: (id) d;
- (id) delegate;

- (int) cursorRow;
- (int) cursorColumn;

- (YLEncoding) encoding;
- (void) setEncoding: (YLEncoding) encoding;

@end
