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
#import "YLConnection.h"
#import "YLPluginLoader.h"

// Elements of the C0 set
#define C0S_NUL     0x00 // NULL
#define C0S_SOH     0x01 // START OF HEADING
#define C0S_STX     0x02 // START OF TEXT
#define C0S_ETX     0x03 // END OF TEXT
#define C0S_EQT     0x04 // END OF TRANSMISSION
#define C0S_ENQ     0x05 // ENQUIRE
#define C0S_ACK     0x06 // ACKNOWLEDGE
#define C0S_BEL     0x07 // BELL (BEEP)
#define C0S_BS      0x08 // BACKSPACE
#define C0S_HT      0x09 // HORIZONTAL TABULATION
#define C0S_LF      0x0A // LINE FEED
#define C0S_VT      0x0B // Virtical Tabulation
#define C0S_FF      0x0C // Form Feed
#define C0S_CR      0x0D // Carriage Return
#define C0S_LS1     0x0E // Shift Out
#define C0S_LS0     0x0F // Shift In
#define C0S_DLE     0x10 // Data Link Escape, normally MODEM
#define C0S_DC1     0x11 // Device Control One, XON
#define C0S_DC2     0x12 // Device Control Two
#define C0S_DC3     0x13 // Device Control Three, XOFF
#define C0S_DC4     0x14 // Device Control Four
#define C0S_NAK     0x15 // Negative Acknowledge
#define C0S_SYN     0x16 // Synchronous Idle
#define C0S_ETB     0x17 // End of Transmission Block
#define C0S_CAN     0x18 // Cancel
#define C0S_EM      0x19 // End of Medium
#define C0S_SUB     0x1A // Substitute
#define C0S_ESC     0x1B // Escape
#define C0S_FS      0x1C // File Separator
#define C0S_GS      0x1D // Group Separator
#define C0S_RS      0x1E // Record Separator
#define C0S_US      0x1F // Unit Separator
//#define ASC_DEL     0x7F // Delete, Ignored on input; not stored in buffer.
#define CSI_ICH     0x40 // INSERT CHARACTER requires DCSM implementation
#define CSI_CUU     0x41 // A, CURSOR UP
#define CSI_CUD     0x42 // B, CURSOR DOWN
#define CSI_CUF     0x43 // C, CURSOR FORWARD
#define CSI_CUB     0x44 // D, CURSOR BACKWARD
#define CSI_CNL     0x45 // E, CURSOR NEXT LINE
#define CSI_CPL     0x46 // F, CURSOR PRECEDING LINE
#define CSI_CHA     0x47 // G, CURSOR CHARACTER ABSOLUTE
#define CSI_CUP     0x48 // H, CURSOR POSITION
#define CSI_CHT     0x49 // I, CURSOR FORWARD TABULATION
#define CSI_ED      0x4A // J, ERASE IN PAGE
#define CSI_EL      0x4B // K, ERASE IN LINE
#define CSI_IL      0x4C // L, INSERT LINE
#define CSI_DL      0x4D // M, DELETE LINE
#define CSI_EF      0x4E // N, Erase in Field, not implemented
#define CSI_EA      0x4F // O, Erase in Area, not implemented
#define CSI_DCH     0x50 // P, DELETE CHARACTER 
#define CSI_SSE     0x51 // Q, ?
#define CSI_CPR     0x52 // R, ACTIVE POSITION REPORT, this is for responding
#define CSI_SU      0x53 // S, ?
#define CSI_SD      0x54 // T, ?
#define CSI_NP      0x55 // U, ?
#define CSI_PP      0x56 // V, ?
#define CSI_CTC     0x57 // W, CURSOR TABULATION CONTROL, not implemented
#define CSI_ECH     0x58 // X, ERASE CHARACTER
#define CSI_CVT     0x59 // Y, CURSOR LINE TABULATION, not implemented
#define CSI_CBT     0x5A // Z, CURSOR BACKWARD TABULATION, not implemented
#define CSI_SRS     0x5B // [, ?
#define CSI_PTX     0x5C // \, ?
#define CSI_SDS     0x5D // ], ?
#define CSISIMD     0x5E // ^, ?
#define CSI_HPA     0x60 // _, CHARACTER POSITION ABSOLUTE
#define CSI_HPR     0x61 // a, CHARACTER POSITION FORWARD
#define CSI_REP     0x62 // b, REPEAT, not implemented
#define CSI_DA      0x63 // c, DEVICE ATTRIBUTES
#define CSI_VPA     0x64 // d, LINE POSITION ABSOLUTE
#define CSI_VPR     0x65 // e, LINE POSITION FORWARD
#define CSI_HVP     0x66 // f, CHARACTER AND LINE POSITION
#define CSI_TBC     0x67 // g, TABULATION CLEAR, not implemented, ignored
#define CSI_SM      0x68 // h, Set Mode, not implemented, ignored
#define CSI_MC      0x69 // i, MEDIA COPY, not implemented, ignored
#define CSI_HPB     0x6A // j, CHARACTER POSITION BACKWARD
#define CSI_VPB     0x6B // k, LINE POSITION BACKWARD
#define CSI_RM      0x6C // l, Reset Mode. not implemented, ignored
#define CSI_SGR     0x6D // m, SELECT GRAPHIC RENDITION
#define CSI_DSR     0x6E // n, DEVICE STATUS REPORT
#define CSI_DAQ     0x6F // o, DEFINE AREA QUALIFICATION, not implemented
#define CSI_DFNKY   0x70 // p, shouldn't be implemented
//0x71 // q,
#define CSI_DECSTBM 0x72 // r, Set Top and Bottom Margins
#define CSI_SCP     0x73 // s, Saves the cursor position.
#define CSI_RCP     0x75 // u, Restores the cursor position.

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
	
	enum { TP_NORMAL, TP_ESCAPE, TP_CONTROL, TP_SCS } _state;
    
//    YLEncoding _encoding;
    
	std::deque<unsigned char> *_csBuf;
	std::deque<int> *_csArg;
	unsigned int _csTemp;
	YLView *_delegate;
    
    int _scrollBeginRow;
    int _scrollEndRow;
    
    BOOL _hasMessage;
    YLConnection *_connection;
    YLPluginLoader *_pluginLoader;
}

/* Input Interface */
- (void) feedData: (NSData *) data connection: (id) connection;
- (void) feedBytes: (const unsigned char *) bytes length: (int) len connection: (id) connection;

/* Start / Stop */
- (void) startConnection ;
- (void) closeConnection ;

/* Clear */
- (void) clearRow: (int) r ;
- (void) clearRow: (int) r fromStart: (int) s toEnd: (int) e ;
- (void) clearAll ;

/* Dirty */
- (BOOL) isDirtyAtRow: (int) r column:(int) c;
- (void) setAllDirty ;
- (void) setDirty: (BOOL) d atRow: (int) r column: (int) c ;
- (void) setDirtyForRow: (int) r ;

/* Access Data */
- (attribute) attrAtRow: (int) r column: (int) c ;
- (NSString *) stringFromIndex: (int) begin length: (int) length ;
- (cell *) cellsOfRow: (int) r ;

/* Update State */
- (void) updateURLStateForRow: (int) r ;
- (void) updateDoubleByteStateForRow: (int) r ;
- (NSString *) urlStringAtRow: (int) r column: (int) c ;

/* Accessor */
- (void) setDelegate: (id) d;
- (id) delegate;
- (int) cursorRow;
- (int) cursorColumn;
- (YLEncoding) encoding;
- (void) setEncoding: (YLEncoding) encoding;
- (BOOL)hasMessage;
- (void)setHasMessage:(BOOL)value;
- (YLConnection *)connection;
- (void)setConnection:(YLConnection *)value;
- (YLPluginLoader *)pluginLoader;
- (void)setPluginLoader:(YLPluginLoader *)value;

@end
