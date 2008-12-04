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


static unsigned short gEmptyAttr;

@implementation YLTerminal

- (id) init {
	if (self = [super init]) {
        _savedCursorX = _savedCursorY = -1;
        _row = [[YLLGlobalConfig sharedInstance] row];
		_column = [[YLLGlobalConfig sharedInstance] column];
        _scrollBeginRow = 0; _scrollEndRow = _row - 1;
		_grid = (cell **) malloc(sizeof(cell *) * _row);
        int i;
        for (i = 0; i < _row; i++)
            // NOTE: in case _cursorX will exceed _column size (at
            // the border of the screen), we allocate one more unit
            // for this array
            _grid[i] = (cell *) malloc(sizeof(cell) * (_column + 1));
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
# pragma mark Input Interface
- (void) feedData: (NSData *) data connection: (id) connection{
	[self feedBytes: (const unsigned char *)[data bytes] length: [data length] connection: connection];
}

#define SET_GRID_BYTE(c) \
if (_cursorX <= _column - 1) { \
    _grid[_cursorY][_cursorX].byte = c; \
    _grid[_cursorY][_cursorX].attr.f.fgColor = _fgColor; \
    _grid[_cursorY][_cursorX].attr.f.bgColor = _bgColor; \
    _grid[_cursorY][_cursorX].attr.f.bold = _bold; \
    _grid[_cursorY][_cursorX].attr.f.underline = _underline; \
    _grid[_cursorY][_cursorX].attr.f.blink = _blink; \
    _grid[_cursorY][_cursorX].attr.f.reverse = _reverse; \
    _grid[_cursorY][_cursorX].attr.f.url = NO; \
    [self setDirty: YES atRow: _cursorY column: _cursorX]; \
    _cursorX++; \
}

- (void) feedBytes: (const unsigned char *) bytes length: (int) len connection: (id) connection {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

	int i, x;
	unsigned char c;

//    NSLog(@"length: %d", len);
	for (i = 0; i < len; i++) {
		c = bytes[i];
//        if (c == 0x00) continue;
        
		switch (_state)
        {
        case TP_NORMAL:
            if (NO) { // code alignment
            } else if (c == 0x00) { // NUL (Null)
                // do nothing
//          } else if (c == 0x03) { // ETX (End of Text)
//          } else if (c == 0x04) { // EOT (End of Transmission)
//          } else if (c == 0x05) { // ENQ (Enquire) (are you there?)
//          } else if (c == 0x06) { // ACK (Acknowledge) (yes I am there)
            } else if (c == 0x07) { // BEL (Beep)
				[[NSSound soundNamed: @"Whit.aiff"] play];
                [self setHasMessage: YES];
			} else if (c == 0x08) { // BS  (Backspace)
				if (_cursorX > 0)
					_cursorX--;
				// If wrap is available, then need to take care of it.
			} else if (c == 0x09) { // HT  (Horizontal TABulation)
                _cursorX=(int(_cursorX/8) + 1) * 8;
                //mjhsieh: this implement is not yet tested
			} else if (c == 0x0A || c == 0x0B || c == 0x0C) {
                // Linefeed(LF) or Vertical tab(VT) or Form feed (FF)
				if (_cursorY == _scrollEndRow) {
//                  if ((i != len - 1 && bytes[i + 1] != 0x0A) || 
//                      (i != 0 && bytes[i - 1] != 0x0A)) {
//                      [_delegate updateBackedImage];
//                      [_delegate extendBottomFrom: _scrollBeginRow to: _scrollEndRow];
//                  }
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
			} else if (c == 0x0D) { // CR  (Carriage Return)
				_cursorX = 0;
            } else if (c == 0x0E) { // SO  (Shift Out)
                //LS1 (Locked Shift-One in Unicode)
                //Selects G1 character set designated by a select character set sequence.
                //However we drop it for now
  				_csBuf->clear();
            } else if (c == 0x0F) { // SI  (Shift In) (^O)
                //LS0 (Locked Shift-Zero in Unicode)
                //Selects G0 character set designated by a select character set sequence.
                //However we drop it for now
  				_csBuf->clear();
//          } else if (c == 0x10) { // DLE (Data Link Escape, normally MODEM)
//          } else if (c == 0x11) { // DC1 (Device Control One, XON)
//          } else if (c == 0x12) { // DC2 (Device Control Two)
//          } else if (c == 0x13) { // DC3 (Device Control Three, XOFF)
//          } else if (c == 0x14) { // DC4 (Device Control Four)
//          } else if (c == 0x15) { // NAK (Negative Acknowledge)
//          } else if (c == 0x16) { // SYN (Synchronous Idle)
//          } else if (c == 0x17) { // ETB (End of Transmission Block)
//          } else if (c == 0x18 || 0x1A) { // CAN (Cancel) or SUB (Substitute)
                //If received during an escape or control sequence, 
                //cancels the sequence and displays substitution character ().
                //SUB is processed as CAN
//          } else if (c == 0x19) { // EM  (End of Medium)
			} else if (c == 0x1B) { // ESC (Escape)
				_state = TP_ESCAPE;
//          } else if (c == 0x1C) { // FS  (File Separator)
//          } else if (c == 0x1D) { // GS  (Group Separator)
//          } else if (c == 0x1E) { // RS  (Record Separator)
//          } else if (c == 0x1F) { // US  (Unit Separator)
//          } else if (c >= 0x80 && c <= 0x99) { // Ignore anyway
//          } else if (c == 0x9A) { // SCI (Single Character Introducer)
//			} else if (c == 0x9B) { // CSI (Control Sequence Introducer) single-
                                    // -character CSI is China-Sea incompatible.
//				_csBuf->clear();
//				_csArg->clear();
//				_csTemp = 0;
//				_state = TP_CONTROL;
//			} else if (c == 0x9C) {
//			} else if (c == 0x9D) {
//			} else if (c == 0x9E) {
//			} else if (c == 0x9F) {
			} else
                SET_GRID_BYTE(c);

            break;

        case TP_ESCAPE:
			if (c == 0x1B) { // ESCESC according to zterm this happens
				_state = TP_ESCAPE;
			} else if (c == 0x5B) { // 0x5B == '['
				_csBuf->clear();
				_csArg->clear();
				_csTemp = 0;
				_state = TP_CONTROL;
			} else if (c == 'M') { // scroll down (cursor up)
				if (_cursorY == _scrollBeginRow) {
					[_delegate updateBackedImage];
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
					[_delegate updateBackedImage];
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
                _cursorX = _savedCursorX;
                _cursorY = _savedCursorY;
                _state = TP_NORMAL;
//			} else if (c == 0x23) { // #,8 --> fill with E
//				_state = TP_FILL
            } else if (c == 0x28 ) { // '(' Font Set G0
                _state = TP_SCS;
            } else if (c == 0x29 ) { // ')' Font Set G1
                _state = TP_SCS;
//          } else if (c == 0x3D ) { // '=' Application keypad mode (vt52)
//				NSLog(@"unprocessed request of application keypad mode");
//              _state = TP_NORMAL;
//          } else if (c == 0x3E ) { // '>' Numeric keypad mode (vt52)
//				NSLog(@"unprocessed request of numeric keypad mode");
//              _state = TP_NORMAL;
			} else if (NO) { //c == 0x45 ) { //  'E' NEL Next Line
				_cursorX = 0;
				if (_cursorY == _scrollEndRow) {
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
//          } else if (c == 0x48 ) { // Set a tab at the current column
//              ignore for now
//              _state = TP_NORMAL;
			} else if (c == 0x63 ) { // 'c' RIS reset
				[self clearAll];
                _cursorX = 0, _cursorY = 0;
				_state = TP_NORMAL;
            } else {
				NSLog(@"unprocessed esc: %c(0x%X)", c, c);
				_state = TP_NORMAL;
			}

            break;

        case TP_SCS:
            if (c == '0') { //Special characters and line drawing set
				//NSLog(@"SCS argument: %c(0x%X)", c, c);
				_state = TP_NORMAL;
            } else if (c == '1') { //Alternate character ROM
				//NSLog(@"SCS argument: %c(0x%X)", c, c);
				_state = TP_NORMAL;
            } else if (c == '2') { //Alternate character ROM - special characters
				//NSLog(@"SCS argument: %c(0x%X)", c, c);
				_state = TP_NORMAL;
            } else if (c == 'A') { //United Kingdom (UK)
				//NSLog(@"SCS argument: %c(0x%X)", c, c);
				_state = TP_NORMAL;
            } else if (c == 'B') { //United States (US)
				//NSLog(@"SCS argument: %c(0x%X)", c, c);
				_state = TP_NORMAL;
            } else {
				NSLog(@"SCS argument exception: %c(0x%X)", c, c);
				_state = TP_NORMAL;
            }
            break;

        case TP_CONTROL:
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
//                        NSLog(@"jump %c, %d x=%d, %d %d", c, _column, _cursorX, (*_csArg)[0], (*_csArg)[1]);
						CURSOR_MOVETO((*_csArg)[1] - 1, (*_csArg)[0] - 1);
//                        [self setDirty: YES atRow: _cursorY column: _cursorX];
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
				} else if (c == 'L') {      // Insert Line
                    int lineNumber = 0;
                    if (_csArg->size() == 0) 
                        lineNumber = 1;
                    else if (_csArg->size() > 0)
                        lineNumber = _csArg->front();

                    int i;
                    for (i = 0; i < lineNumber; i++) {
                        [self clearRow: _row - 1];
                        cell *emptyRow = [self cellsOfRow: _row - 1];
                        int r;
                        for (r = _row - 1; r > _cursorY; r--)
                            _grid[r] = _grid[r - 1];
                        _grid[_cursorY] = emptyRow;
                    }
                    for (i = _cursorY; i < _row; i++)
                        [self setDirtyForRow: i];
				} else if (c == 'M') {      // Delete Line
                    int lineNumber = 0;
                    if (_csArg->size() == 0) 
                        lineNumber = 1;
                    else if (_csArg->size() > 0)
                        lineNumber = _csArg->front();
                    
                    int i;
                    for (i = 0; i < lineNumber; i++) {
                        [self clearRow: _cursorY];
                        cell *emptyRow = [self cellsOfRow: _cursorY];
                        int r;
                        for (r = _cursorY; r < _row - 1; r++)
                            _grid[r] = _grid[r + 1];
                        _grid[_row - 1] = emptyRow;
                    }
                    for (i = _cursorY; i < _row; i++)
                        [self setDirtyForRow: i];
				} else if (c == 'P') {
                    int i;
                    int p;
                    if (_csArg->size() == 1) {
                        p = _csArg->front();
                    } else {
                        p = 1;
                    }
                    if (p > 0) {
                        for (i = _cursorX; i <= _column - 1; i++){
                            if ( i <= _column - 1 - p ) {
                                _grid[_cursorY][i] = _grid[_cursorY][i+p];
                            } else {
                                _grid[_cursorY][i].byte = '\0';
						        _grid[_cursorY][i].attr.v = gEmptyAttr;
                                _grid[_cursorY][i].attr.f.bgColor = _bgColor;
                                _dirty[_cursorY * _column + i] = YES;
                            }
                        }
                    }
                } else if (c == 'c') {  // Device Attributes (DA)
                                        // Computer requests terminal identify itself.
                    if ( _csArg->empty() || _csArg->size() == 1 ){
                        unsigned char cmd[10]; // 10 should be enough for now
                        unsigned int cmdLength = 0;
                        // Assuming I am a vt102, TODO: have a global variable for TERM
				        cmd[cmdLength++] = 0x1B;
				        cmd[cmdLength++] = 0x5B;
				        cmd[cmdLength++] = 0x3F;
				        cmd[cmdLength++] = 0x36;
				        cmd[cmdLength++] = 0x63;
                        //[[self frontMostConnection] sendBytes: cmd length: cmdLength];
                        [[self connection] sendBytes:cmd length:cmdLength];
                    }
//              } else if (c == 'd') {  //
				} else if (c == 'g') {	// Clear a tab at the current column
                    int p = 1;
                    if (_csArg->size() == 1){
                        p = _csArg->front();
                    }
                    if (p == 3) {
                        NSLog(@"Ignoring request to clear all horizontal tab stops.");
                    } else
                        NSLog(@"Ignoring request to clear one horizontal tab stop.");

				} else if (c == 'h') {	// set mode
                    while (!_csArg->empty()) {
                        int p = _csArg->front();
						_csArg->pop_front();
                        if (p == 0) {
//                          NSLog(@"ignore re/setting mode 0");
//                      } else if (p == 1) {
//When set, the cursor keys send an ESC O prefix, rather than ESC [
//                      } else if (p == 2) {
//                          NSLog(@"ignore re/setting Keyboard Action Mode (AM)");
//                      } else if (p == 4) {
//                          NSLog(@"ignore re/setting Replace Mode (IRM)");
//                      } else if (p == 7) {
// wrap
//                      } else if (p == 12) {
//                          NSLog(@"ignore re/setting Send/receive (SRM)");
//                      } else if (p == 20) {
//                          NSLog(@"ignore re/setting Normal Linefeed (LNM)");
                        } else
                            NSLog(@"unsupported mode setting %d",p);
                    }
				} else if (c == 'l') {// reset mode
                    while (!_csArg->empty()) {
                        int p = _csArg->front();
						_csArg->pop_front();
						NSLog(@"unsupported mode resetting %d",p);
                    }						
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
                    _savedCursorX = _cursorX;
                    _savedCursorY = _cursorY;
				} else if (c == 'u') {
                    if (_savedCursorX >= 0 && _savedCursorY >= 0) {
                        _cursorX = _savedCursorX;
                        _cursorY = _savedCursorY;
                    }
				} else {
					NSLog(@"unsupported control sequence: %c", c);
				}
				_csArg->clear();
				_state = TP_NORMAL;
			}

            break;
		}
	}

    for (i = 0; i < _row; i++) {
        [self updateDoubleByteStateForRow: i];
        [self updateURLStateForRow: i];
    }
    [_delegate performSelector: @selector(tick:)
					withObject: nil
					afterDelay: 0.07];
    
    [pool release];
}

# pragma mark -
# pragma mark Start / Stop

- (void) startConnection {
    [self clearAll];
    [_delegate updateBackedImage];
	[_delegate setNeedsDisplay: YES];
}

- (void) closeConnection {
	[_delegate setNeedsDisplay: YES];
}

# pragma mark -
# pragma mark Clear

- (void) clearAll {
    _cursorX = _cursorY = 0;
    attribute t;
    t.f.fgColor = [YLLGlobalConfig sharedInstance]->_fgColorIndex;
    t.f.bgColor = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
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
    _fgColor = [YLLGlobalConfig sharedInstance]->_fgColorIndex;
    _bgColor = [YLLGlobalConfig sharedInstance]->_bgColorIndex;
    _csTemp = 0;
    _state = TP_NORMAL;
    _bold = NO;
	_underline = NO;
	_blink = NO;
	_reverse = NO;
}

- (void) clearRow: (int) r {
    [self clearRow: r fromStart: 0 toEnd: _column - 1];
}

- (void) clearRow: (int) r fromStart: (int) s toEnd: (int) e {
    int i;
    for (i = s; i <= e; i++) {
        _grid[r][i].byte = '\0';
        _grid[r][i].attr.v = gEmptyAttr;
        _grid[r][i].attr.f.bgColor = _bgColor;
        _dirty[r * _column + i] = YES;
    }
}

# pragma mark -
# pragma mark Dirty

- (void) setAllDirty {
	int i, end = _column * _row;
	for (i = 0; i < end; i++)
		_dirty[i] = YES;
}

- (void) setDirtyForRow: (int) r {
	int i, end = _column * _row;
	for (i = r * _column; i < end; i++)
		_dirty[i] = YES;
}

- (BOOL) isDirtyAtRow: (int) r column:(int) c {
	return _dirty[(r) * _column + (c)];
}

- (void) setDirty: (BOOL) d atRow: (int) r column: (int) c {
	_dirty[(r) * _column + (c)] = d;
}

# pragma mark -
# pragma mark Access Data

- (attribute) attrAtRow: (int) r column: (int) c {
	return _grid[r][c].attr;
}

- (NSString *) stringFromIndex: (int) begin length: (int) length {
    int i, j;
    unichar textBuf[_row * (_column + 1) + 1];
    unichar firstByte = 0;
    int bufLength = 0;
    int spacebuf = 0;
    for (i = begin; i < begin + length; i++) {
        int x = i % _column;
        int y = i / _column;
        if (x == 0 && i != begin && i - 1 < begin + length) { // newline
            [self updateDoubleByteStateForRow: y];
            unichar cr = 0x000D;
            textBuf[bufLength++] = cr;
            spacebuf = 0;
        }
        int db = _grid[y][x].attr.f.doubleByte;
        if (db == 0) {
            if (_grid[y][x].byte == '\0' || _grid[y][x].byte == ' ')
                spacebuf++;
            else {
                for (j = 0; j < spacebuf; j++)
                    textBuf[bufLength++] = ' ';
                textBuf[bufLength++] = _grid[y][x].byte;
                spacebuf = 0;
            }
        } else if (db == 1) {
            firstByte = _grid[y][x].byte;
        } else if (db == 2 && firstByte) {
            int index = (firstByte << 8) + _grid[y][x].byte - 0x8000;
            for (j = 0; j < spacebuf; j++)
                textBuf[bufLength++] = ' ';
            textBuf[bufLength++] = ([[[self connection] site] encoding] == YLBig5Encoding) ? B2U[index] : G2U[index];
            spacebuf = 0;
        }
    }
    if (bufLength == 0) return nil;
    return [[[NSString alloc] initWithCharacters: textBuf length: bufLength] autorelease];
}

- (cell *) cellsOfRow: (int) r {
	return _grid[r];
}

# pragma mark -
# pragma mark Update State

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
    /* TODO: use DFA to reduce the computation  */
    char *protocols[] = {"http://", "https://", "ftp://", "telnet://", "bbs://", "ssh://", "mailto:"};
    int protocolNum = 7;
    
    BOOL urlState = NO;
    
    if (r > 0) 
        urlState = _grid[r - 1][_column - 1].attr.f.url;
    
	int i;
	for (i = 0; i < _column; i++) {
        if (urlState) {
            unsigned char c = currRow[i].byte;
            if (0x21 > c || c > 0x7E || c == ')')
                urlState = NO;
        } else {
            int p;
            for (p = 0; p < protocolNum; p++) {
                int s, len = strlen(protocols[p]);
                BOOL match = YES;
                for (s = 0; s < len; s++) 
                    if (currRow[i + s].byte != protocols[p][s] || currRow[i + s].attr.f.doubleByte) {
                        match = NO;
                        break;
                    }
                
                if (match) {
                    urlState = YES;
                    break;
                }
            }
        }            
        
        if (currRow[i].attr.f.url != urlState) {
            currRow[i].attr.f.url = urlState;
            [self setDirty: YES atRow: r column: i];
            //            [_delegate displayCellAtRow: r column: i];
            /* TODO: Do not regenerate the region. Draw the url line instead. */
        }
	}
}

- (NSString *) urlStringAtRow: (int) r column: (int) c {
    if (!_grid[r][c].attr.f.url) return nil;

    while (_grid[r][c].attr.f.url) {
        c--;
        if (c < 0) {
            c = _column - 1;
            r--;
        }
        if (r < 0) 
            break;
    }
    
    c++;
    if (c >= _column) {
        c = 0;
        r++;
    }
    
    NSMutableString *urlString = [NSMutableString string];
    while (_grid[r][c].attr.f.url) {
        [urlString appendFormat: @"%c", _grid[r][c].byte];
        c++;
        if (c >= _column) {
            c = 0;
            r++;
        }
        if (r >= _row) 
            break;
    }
    return urlString;
}

# pragma mark -
# pragma mark Accessor

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

- (YLEncoding)encoding {
    return [[[self connection] site] encoding];
}

- (void)setEncoding:(YLEncoding)encoding {
    [[[self connection] site] setEncoding: encoding];
}

- (BOOL)hasMessage {
    return _hasMessage;
}

- (void)setHasMessage:(BOOL)value {
    if (_hasMessage != value) {
        _hasMessage = value;
        YLLGlobalConfig *config = [YLLGlobalConfig sharedInstance];
        if (_hasMessage) {
            [NSApp requestUserAttention: ([config repeatBounce] ? NSCriticalRequest : NSInformationalRequest)];
            if (_connection != [[_delegate selectedTabViewItem] identifier] || ![NSApp isActive]) { /* Not selected tab */
                [_connection setIcon: [NSImage imageNamed: @"message.pdf"]];
                [config setMessageCount: [config messageCount] + 1];
            } else {
                _hasMessage = NO;
            }
        } else {
            [config setMessageCount: [config messageCount] - 1];
            if ([_connection connected])
                [_connection setIcon: [NSImage imageNamed: @"connect.pdf"]];
            else
                [_connection setIcon: [NSImage imageNamed: @"offline.pdf"]];
        }        
    }
}

- (YLConnection *)connection {
    return _connection;
}

- (void)setConnection:(YLConnection *)value {
    _connection = value;
}


@end
