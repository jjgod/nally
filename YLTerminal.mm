//
//  YLTerminal.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/9/10.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLTerminal.h"
#import "YLLGlobalConfig.h"
#import "encoding.h"

#define CURSOR_MOVETO(x, y)		do {\
									_cursorX = (x); _cursorY = (y); \
									if (_cursorX < 0) _cursorX = 0; if (_cursorX >= _column) _cursorX = _column - 1;\
									if (_cursorY < 0) _cursorY = 0; if (_cursorY >= _row) _cursorY = _row - 1;\
								} while(0);

BOOL isC0Control(unsigned char c) { return (c <= 0x1F); }
BOOL isSPACE(unsigned char c) { return (c == 0x20 || c == 0xA0); }
BOOL isIntermediate(unsigned char c) { return (c >= 0x20 && c <= 0x2F); }
BOOL isParameter(unsigned char c) { return (c >= 0x30 && c <= 0x3F); }
BOOL isUppercase(unsigned char c) { return (c >= 0x40 && c <= 0x5F); }
BOOL isLowercase(unsigned char c) { return (c >= 0x60 && c <= 0x7E); }
BOOL isDelete(unsigned char c) { return (c == 0x7F); }
BOOL isC1Control(unsigned char c) { return(c >= 0x80 && c <= 0x9F); }
BOOL isG1Displayable(unsigned char c) { return(c >= 0xA1 && c <= 0xFE); }
BOOL isSpecial(unsigned char c) { return(c == 0xA0 || c == 0xFF); }
BOOL isAlphabetic(unsigned char c) { return(c >= 0x40 && c <= 0x7E); }

ASCII_CODE asciiCodeFamily(unsigned char c) {
	if (isC0Control(c)) return C0;
	if (isIntermediate(c)) return INTERMEDIATE;
	if (isAlphabetic(c)) return ALPHABETIC;
	if (isDelete(c)) return DELETE;
	if (isC1Control(c)) return C1;
	if (isG1Displayable(c)) return G1;
	if (isSpecial(c)) return SPECIAL;
	return ERROR;
}

static SEL normal_table[256];
static unsigned short gEmptyAttr;

@implementation YLTerminal

+ (void) initialize {
	int i;
	/* C0 control character */
	for (i = 0x00; i <= 0x1F; i++)
		normal_table[i] = NULL;
	normal_table[0x07] = @selector(beep);
	normal_table[0x08] = @selector(backspace);
	normal_table[0x0A] = @selector(lf);
	normal_table[0x0D] = @selector(cr);
	normal_table[0x1B] = @selector(beginESC);
	
	/* C1 control character */
	for (i = 0x80; i <=0x9F; i++)
		normal_table[i] = NULL;
	normal_table[0x85] = @selector(newline);
	normal_table[0x9B] = @selector(beginControl);
	
}

- (void) clearAll {
    _cursorX = _cursorY = 0;
    attribute t;
    t.f.fgColor = 7;
    t.f.bgColor = 9;
    t.f.bold = 0;
    t.f.underline = 0;
    t.f.blink = 0;
    t.f.reverse = 0;
    t.f.url = 0;
    t.f.nothing = 0;
    gEmptyAttr = t.v;
    int i;
    for (i = 0; i < _row; i++) 
        [self clearRow: i];

    if (_csBuf)
        _csBuf->clear();
    else
        _csBuf = new std::deque<unsigned char>();
    if (_csArg)
        _csArg->clear();
    else
        _csArg = new std::deque<int>();
    _fgColor = 7;
    _bgColor = 9;
    _csTemp = 0;
    _state = TP_NORMAL;
    _bold = NO;
	_underline = NO;
	_blink = NO;
	_reverse = NO;
}

- (id) init {
	if (self = [super init]) {
        _savedCursorX = _savedCursorY = 0;
        _row = [[YLLGlobalConfig sharedInstance] row];
		_column = [[YLLGlobalConfig sharedInstance] column];
        _scrollBeginRow = 0; _scrollEndRow = _row - 1;
		_grid = (cell **) malloc(sizeof(cell *) * _row);
        int i;
        for (i = 0; i < _row; i++)
            _grid[i] = (cell *) malloc(sizeof(cell) * _column);
		_dirty = (char *) malloc(sizeof(char) * (_row * _column));
        [self clearAll];
	}
	return self;
}

- (void) dealloc {
	delete _csBuf;
	delete _csArg;
    int i;
    for (i = 0; i < _row; i++)
        free(_grid[i]);
    free(_grid);
	[super dealloc];
}

# pragma mark -
# pragma mark Cursor Movement


# pragma mark -
# pragma mark Input Interface
- (void) feedData: (NSData *) data connection: (id) connection{
	[self feedBytes: (const unsigned char *)[data bytes] length: [data length] connection: connection];
}

- (void) feedBytes: (const unsigned char *) bytes length: (int) len connection: (id) connection {
	int i, x;
	unsigned char c;
	[_delegate performSelector: @selector(tick:)
					withObject: nil
					afterDelay: 0.02];
	
	for (i = 0; i < len; i++) {
		c = bytes[i];
		if (_state == TP_NORMAL) {
            if (c == 0x00) {
                // do nothing
            } else if (c == 0x07) { // Beep
				NSBeep();
                if (connection != [[_delegate selectedTabViewItem] identifier]) {
                    [connection setValue: [NSImage imageNamed: @"message.pdf"] forKey: @"icon"];
                }
			} else if (c == 0x08) { // Backspace
				if (_cursorX > 0)
					_cursorX--;
			} else if (c == 0x0A) { // Linefeed 
				if (_cursorY == _scrollEndRow) {
                    if ((i != len - 1 && bytes[i + 1] != 0x0A) || 
                        (i != 0 && bytes[i - 1] != 0x0A)) {
                        [_delegate update];
                        [_delegate extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
                    }
                    cell *emptyLine = _grid[_scrollBeginRow];
                    [self clearRow: _scrollBeginRow];
                    
                    for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
                        _grid[x] = _grid[x + 1];
                    _grid[_scrollEndRow] = emptyLine;
					[self setAllDirty];
				} else {
					_cursorY++;
                    if (_cursorY >= _row) _cursorY = _row - 1;
				}
			} else if (c == 0x0D) { // Carriage Return
				_cursorX = 0;
			} else if (c == 0x1B) { // ESC
				_state = TP_ESCAPE;
			} else if (c == 0x9B) { // Control Sequence Introducer
				_csBuf->clear();
				_csArg->clear();
				_csTemp = 0;
				_state = TP_CONTROL;
			} else {
				_grid[_cursorY][_cursorX].byte = c;
				_grid[_cursorY][_cursorX].attr.f.fgColor = _fgColor;
				_grid[_cursorY][_cursorX].attr.f.bgColor = _bgColor;
				_grid[_cursorY][_cursorX].attr.f.bold = _bold;
				_grid[_cursorY][_cursorX].attr.f.underline = _underline;
				_grid[_cursorY][_cursorX].attr.f.blink = _blink;
				_grid[_cursorY][_cursorX].attr.f.reverse = _reverse;
                _grid[_cursorY][_cursorX].attr.f.url = NO;
				[self setDirty: YES atRow: _cursorY column: _cursorX];
				_cursorX++;
			}
		} else if (_state == TP_ESCAPE) {
			if (c == 0x5B) { // 0x5B == '['
				_csBuf->clear();
				_csArg->clear();
				_csTemp = 0;
				_state = TP_CONTROL;
			} else if (c == 'M') { // scroll down (cursor up)
				if (_cursorY == _scrollBeginRow) {
					[_delegate update];
					[_delegate extendTopFrom: _scrollBeginRow to: _scrollEndRow];
                    cell *emptyLine = _grid[_scrollEndRow];
                    [self clearRow: _scrollEndRow];
                    
                    for (x = _scrollEndRow; x > _scrollBeginRow; x--) 
                        _grid[x] = _grid[x - 1];
                    _grid[_scrollBeginRow] = emptyLine;
					[self setAllDirty];
				} else {
					_cursorY--;
                    if (_cursorY < 0) _cursorY = 0;
				}
				_state = TP_NORMAL;
            } else if (c == 'D') { // scroll up (cursor down)
                if (_cursorY == _scrollEndRow) {
					[_delegate update];
					[_delegate extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
                    cell *emptyLine = _grid[_scrollBeginRow];
                    [self clearRow: _scrollBeginRow];
                    
                    for (x = _scrollBeginRow; x < _scrollEndRow; x++) 
                        _grid[x] = _grid[x + 1];
                    _grid[_scrollEndRow] = emptyLine;
					[self setAllDirty];
				} else {
					_cursorY++;
                    if (_cursorY >= _row) _cursorY = _row - 1;
				}
                _state = TP_NORMAL;
			} else if (c == '7') { // Save cursor
                _savedCursorX = _cursorX;
                _savedCursorY = _cursorY;
                _state = TP_NORMAL;
			} else if (c == '8') { // Restore cursor
                _savedCursorX = _cursorX;
                _savedCursorY = _cursorY;
                _state = TP_NORMAL;
            } else {
				NSLog(@"unprocessed esc: %c(0x%X)", c, c);
				_state = TP_NORMAL;
			}
		} else if (_state == TP_CONTROL) {
			if (isParameter(c)) {
				_csBuf->push_back(c);
				if (c >= '0' && c <= '9') {
					_csTemp = _csTemp * 10 + (c - '0');
				} else if (!_csBuf->empty()) {
					_csArg->push_back(_csTemp);
					_csTemp = 0;
					_csBuf->clear();
				}
			} else {
				if (!_csBuf->empty()) {
					_csArg->push_back(_csTemp);
					_csTemp = 0;
					_csBuf->clear();
				}
				
				if (NO) {
					// just for code alignment...
				} else if (c == 'A') {		// Cursor Up
					if (_csArg->size() > 0)
						_cursorY -= _csArg->front();
					else
						_cursorY--;
					
					if (_cursorY < 0) _cursorY = 0;
				} else if (c == 'B') {		// Cursor Down
					if (_csArg->size() > 0)
						_cursorY += _csArg->front();
					else
						_cursorY++;
					
					if (_cursorY >= _row) _cursorY = _row - 1;
				} else if (c == 'C') {		// Cursor Right
					if (_csArg->size() > 0)
						_cursorX += _csArg->front();
					else
						_cursorX++;
					
					if (_cursorX >= _column) _cursorX = _column - 1;					
				} else if (c == 'D') {		// Cursor Left
					if (_csArg->size() > 0)
						_cursorX -= _csArg->front();
					else
						_cursorX--;
					
					if (_cursorX < 0) _cursorX = 0;
				} else if (c == 'f' || c == 'H') {	// Cursor Position
					/* 
						^[H			: go to row 1, column 1
						^[3H		: go to row 3, column 1
						^[3;4H		: go to row 3, column 4
					 */
					if (_csArg->size() == 0) {
						_cursorX = 0, _cursorY = 0;
					} else if (_csArg->size() == 1) {
                        if ((*_csArg)[0] < 1) (*_csArg)[0] = 1;
						CURSOR_MOVETO(0, _csArg->front() - 1);
					} else {
                        if ((*_csArg)[0] < 1) (*_csArg)[0] = 1;
                        if ((*_csArg)[1] < 1) (*_csArg)[1] = 1;
						CURSOR_MOVETO((*_csArg)[1] - 1, (*_csArg)[0] - 1);
					}
				} else if (c == 'J') {		// Erase Region (cursor does not move)
					/* 
						^[J, ^[0J	: clear from cursor position to end
						^[1J		: clear from start to cursor position
						^[2J		: clear all
					 */
					int j;
					if (_csArg->size() == 0 || _csArg->front() == 0) {
                        [self clearRow: _cursorY fromStart: _cursorX toEnd: _column - 1];
                        for (j = _cursorY + 1; j < _row; j++)
                            [self clearRow: j];
                    } else if (_csArg->size() == 1 && _csArg->front() == 1) {
                        [self clearRow: _cursorY fromStart: 0 toEnd: _cursorX];
                        for (j = 0; j < _cursorY; j++)
                            [self clearRow: j];
                    } else if (_csArg->size() == 1 && _csArg->front() == 2) {
                        [self clearAll];
                    }
				} else if (c == 'K') {		// Erase Line (cursor does not move)
					/* 
						^[K, ^[0K	: clear from cursor position to end of line
						^[1K		: clear from start of line to cursor position
						^[2K		: clear whole line
					 */
					if (_csArg->size() == 0 || _csArg->front() == 0) {
                        [self clearRow: _cursorY fromStart: _cursorX toEnd: _column - 1];
                    } else if (_csArg->size() == 1 && _csArg->front() == 1) {
                        [self clearRow: _cursorY fromStart: 0 toEnd: _cursorX];
                    } else if (_csArg->size() == 1 && _csArg->front() == 2) {
                        [self clearRow: _cursorY];
                    }
				} else if (c == 'L') {
				} else if (c == 'M') {
				} else if (c == 'm') {
					if (_csArg->empty()) { // clear
						_fgColor = 7;
						_bgColor = 9;
						_bold = NO;
						_underline = NO;
						_blink = NO;
						_reverse = NO;
					} else {
						while (!_csArg->empty()) {
							int p = _csArg->front();
							_csArg->pop_front();
							if (p  == 0) {
								_fgColor = 7;
								_bgColor = 9;
								_bold = NO;
								_underline = NO;
								_blink = NO;
								_reverse = NO;
							} else if (30 <= p && p <= 39) {
								_fgColor = p - 30;
							} else if (40 <= p && p <= 49) {
								_bgColor = p - 40;
							} else if (p == 1) {
								_bold = YES;
							} else if (p == 4) {
								_underline = YES;
							} else if (p == 5) {
								_blink = YES;
							} else if (p == 7) {
								_reverse = YES;
							}
						}
					}
				} else if (c == 'r') {
                    if (_csArg->size() == 0) {
                        _scrollBeginRow = 0;
                        _scrollEndRow = _row - 1;
                    } else if (_csArg->size() == 2) {
                        int s = (*_csArg)[0];
                        int e = (*_csArg)[1];
                        if (s > e) s = (*_csArg)[1], e = (*_csArg)[0];
                        _scrollBeginRow = s - 1;
                        _scrollEndRow = e - 1;
                    }
				} else if (c == 's') {
					
				} else if (c == 'u') {
					
				} else {
					NSLog(@"unsupported control sequence: %c", c);
				}
				_csArg->clear();
				_state = TP_NORMAL;
			}
		}
	}

//	[_delegate update];
}

# pragma mark -
# pragma mark 

- (void) startConnection {
    [self clearAll];
	[_delegate setNeedsDisplay: YES];
}

- (void) closeConnection {
	[_delegate setNeedsDisplay: YES];
}

- (void) clearRow: (int) r {
    [self clearRow: r fromStart: 0 toEnd: _column - 1];
}

- (void) clearRow: (int) r fromStart: (int) s toEnd: (int) e {
    int i;
    for (i = s; i <= e; i++) {
        _grid[r][i].byte = '\0';
        _grid[r][i].attr.v = gEmptyAttr;
        _dirty[r * _column + i] = YES;
    }
}

- (void) setAllDirty {
	int i, end = _column * _row;
	for (i = 0; i < end; i++)
		_dirty[i] = YES;
}

- (BOOL) isDirtyAtRow: (int) r column:(int) c {
	return _dirty[(r) * _column + (c)];
}

- (void) setDirty: (BOOL) d atRow: (int) r column: (int) c {
	_dirty[(r) * _column + (c)] = d;
}

- (attribute) attrAtRow: (int) r column: (int) c {
	return _grid[(r + _offset) % _row][c].attr;
}

- (NSString *) stringFromIndex: (int) begin length: (int) length {
    int i;
    unichar textBuf[_row * (_column + 1) + 1];
    unichar firstByte = 0;
    int bufLength = 0;
    for (i = begin; i < begin + length; i++) {
        int x = i % _column;
        int y = i / _column;
        if (x == 0 && i != begin && i - 1 < begin + length) {
            [self updateDoubleByteStateForRow: y];
            unichar cr = 0x000D;
            textBuf[bufLength++] = cr;
        }
        int db = _grid[y][x].attr.f.doubleByte;
        if (db == 0) {
            textBuf[bufLength++] = _grid[y][x].byte;
        } else if (db == 1) {
            firstByte = _grid[y][x].byte;
        } else if (db == 2 && firstByte) {
            int index = (firstByte << 8) + _grid[y][x].byte - 0x8000;
            textBuf[bufLength++] = B2U[index];
        }
    }
    if (bufLength == 0) return nil;
    return [[[NSString alloc] initWithCharacters: textBuf length: bufLength] autorelease];
}

- (cell *) cellsOfRow: (int) r {
	return _grid[r];
}

- (void) updateDoubleByteStateForRow: (int) r {
	cell *currRow = _grid[r];
	int i, db = 0;
	for (i = 0; i < _column; i++) {
		if (db == 0 || db == 2) {
			if (currRow[i].byte > 0x7F) db = 1;
			else db = 0;
		} else { // db == 1
			db = 2;
		}
		currRow[i].attr.f.doubleByte = db;
	}
}

- (void) updateURLStateForRow: (int) r {
	cell *currRow = _grid[r];
    int httpLength = 7; // http://
    int httpsLength = 8; // https://
    BOOL urlState = NO;
    
	int i;
	for (i = 0; i < _column; i++) {
        if (urlState) {
            unsigned char c = currRow[i].byte;
            if (0x21 <= c && c <= 0x7E) {
                currRow[i].attr.f.url = YES;                
            } else {
                urlState = NO;
                currRow[i].attr.f.url = NO;
            }
        } else if (i + httpLength < _column && 
            currRow[i + 0].byte == 'h' &&
            currRow[i + 1].byte == 't' && 
            currRow[i + 2].byte == 't' &&
            currRow[i + 3].byte == 'p' &&
            currRow[i + 4].byte == ':' &&
            currRow[i + 5].byte == '/' &&
            currRow[i + 6].byte == '/') {
            urlState = YES;
            (currRow + i)->attr.f.url = YES;
        } else if (i + httpsLength < _column && 
                   currRow[i + 0].byte == 'h' &&
                   currRow[i + 1].byte == 't' && 
                   currRow[i + 2].byte == 't' &&
                   currRow[i + 3].byte == 'p' &&
                   currRow[i + 4].byte == 's' &&
                   currRow[i + 5].byte == ':' &&
                   currRow[i + 6].byte == '/' &&
                   currRow[i + 7].byte == '/' ) {
            urlState = YES;
            currRow[i].attr.f.url = YES;
        } else {
            currRow[i].attr.f.url = NO;
        }
	}
}

- (void) setDelegate: (id) d {
	_delegate = d; // Yes, this is delegation. We shouldn't own the delegation object.
}

- (id) delegate {
	return _delegate;
}

- (int) cursorRow {
    return _cursorY;
}

- (int) cursorColumn {
    return _cursorX;
}

@end
