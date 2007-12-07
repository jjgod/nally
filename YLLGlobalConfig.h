//
//  YLLGlobalConfig.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#define NUM_COLOR 10

@interface YLLGlobalConfig : NSObject {
@public
	int _row;
	int _column;
	
	int _cellWidth;
	int _cellHeight;
    
    BOOL _showHiddenText;
	BOOL _blinkTicker;
    BOOL _shouldSmoothFonts;
    BOOL _detectDoubleByte;
    
	CTFontRef _cCTFont;
	CTFontRef _eCTFont;
	CGFontRef _cCGFont;
	CGFontRef _eCGFont;
	
	NSColor *_colorTable[2][NUM_COLOR];

	CFDictionaryRef _cCTAttribute[2][NUM_COLOR];
	CFDictionaryRef _eCTAttribute[2][NUM_COLOR];
}

+ (YLLGlobalConfig *) sharedInstance;

- (NSArray *) encodingArray;
- (void) setEncodingArray: (NSArray *) a;

- (int)row;
- (void)setRow:(int)value;

- (int)column;
- (void)setColumn:(int)value;

- (BOOL)showHiddenText;
- (void)setShowHiddenText:(BOOL)value;

- (BOOL)shouldSmoothFonts;
- (void)setShouldSmoothFonts:(BOOL)value;

- (BOOL)detectDoubleByte;
- (void)setDetectDoubleByte:(BOOL)value;

- (int)cellWidth;
- (void)setCellWidth:(int)value;

- (int)cellHeight;
- (void)setCellHeight:(int)value;

- (NSColor *) colorAtIndex: (int) i hilite: (BOOL) h ;
- (void) setColor: (NSColor *) c hilite: (BOOL) h atIndex: (int) i ;

- (BOOL)blinkTicker;
- (void)setBlinkTicker:(BOOL)value;
- (void)updateBlinkTicker;
@end
