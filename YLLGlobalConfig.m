//
//  YLLGlobalConfig.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLLGlobalConfig.h"

static YLLGlobalConfig *sSharedInstance;
static NSArray *gEncodingArray = nil;

@implementation YLLGlobalConfig
+ (YLLGlobalConfig*) sharedInstance {
	return sSharedInstance ?: [[YLLGlobalConfig new] autorelease];
}

+ (void) initialize {
    gEncodingArray = 
    [[NSArray arrayWithObjects: @"Big5", @"GBK", nil] retain];
}

- (id) init {
	if(sSharedInstance) {
		[self release];
	} else if(self = sSharedInstance = [[super init] retain]) {
        [self setShowHiddenText: [[NSUserDefaults standardUserDefaults] boolForKey: @"ShowHiddenText"]];
        [self setShouldSmoothFonts: [[NSUserDefaults standardUserDefaults] boolForKey: @"ShouldSmoothFonts"]];
        [self setDetectDoubleByte: [[NSUserDefaults standardUserDefaults] boolForKey: @"DetectDoubleByte"]];

		/* init code */
		_row = 24;
		_column = 80;
		_cellWidth = 12;
		_cellHeight = 24;

		_colorTable[0][0] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][0] = [[NSColor colorWithDeviceRed: 0.25 green: 0.25 blue: 0.25 alpha: 1.0] retain];
		_colorTable[0][1] = [[NSColor colorWithDeviceRed: 0.50 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][1] = [[NSColor colorWithDeviceRed: 1.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[0][2] = [[NSColor colorWithDeviceRed: 0.00 green: 0.50 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][2] = [[NSColor colorWithDeviceRed: 0.00 green: 1.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[0][3] = [[NSColor colorWithDeviceRed: 0.50 green: 0.50 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][3] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[0][4] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][4] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][5] = [[NSColor colorWithDeviceRed: 0.50 green: 0.00 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][5] = [[NSColor colorWithDeviceRed: 1.00 green: 0.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][6] = [[NSColor colorWithDeviceRed: 0.00 green: 0.50 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][6] = [[NSColor colorWithDeviceRed: 0.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][7] = [[NSColor colorWithDeviceRed: 0.50 green: 0.50 blue: 0.50 alpha: 1.0] retain];
		_colorTable[1][7] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][8] = [[NSColor colorWithDeviceRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];
		_colorTable[1][8] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];
		_colorTable[0][9] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];
		_colorTable[1][9] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0] retain];  // Background-Color

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        NSString *eFontName = [defaults stringForKey: @"EnglishFontName"];
        NSString *cFontName = [defaults stringForKey: @"ChineseFontName"];

        if (! eFontName)
            eFontName = @"Monaco";

        if (! cFontName)
            cFontName = @"STHeiti";

        [defaults setObject: eFontName forKey: @"EnglishFontName"];
        [defaults setObject: cFontName forKey: @"ChineseFontName"];

        [defaults synchronize];

		int i, j;
		ATSUFontID cATSUFontID, eATSUFontID;
		char *cATSUFontName = (char *)[cFontName UTF8String];
        char *eATSUFontName = (char *)[eFontName UTF8String];
		
		ATSUFindFontFromName(cATSUFontName, strlen(cATSUFontName), kFontFullName, kFontNoPlatform, kFontNoScript, kFontNoLanguage, &cATSUFontID);
		ATSUFindFontFromName(eATSUFontName, strlen(eATSUFontName), kFontFullName, kFontNoPlatform, kFontNoScript, kFontNoLanguage, &eATSUFontID);

		_cCTFont = CTFontCreateWithPlatformFont(cATSUFontID, 22.0, NULL, NULL);
		_eCTFont = CTFontCreateWithPlatformFont(eATSUFontID, 18.0, NULL, NULL);
		_cCGFont = CTFontCopyGraphicsFont(_cCTFont, NULL);
		_eCGFont = CTFontCopyGraphicsFont(_eCTFont, NULL);
		
		for (i = 0; i < NUM_COLOR; i++) 
			for (j = 0; j < 2; j++) {
				
				CFStringRef cfKeys[] = {kCTFontAttributeName, kCTForegroundColorAttributeName};
                
				CFTypeRef cfValues[] = {_cCTFont, _colorTable[j][i]};
				_cCTAttribute[j][i] = CFDictionaryCreate(kCFAllocatorDefault, 
														 (const void **) cfKeys, 
														 (const void **) cfValues, 
														 2, 
														 &kCFTypeDictionaryKeyCallBacks, 
														 &kCFTypeDictionaryValueCallBacks);
				cfValues[0] = _eCTFont;
				_eCTAttribute[j][i] = CFDictionaryCreate(kCFAllocatorDefault, 
														 (const void **) cfKeys, 
														 (const void **) cfValues, 
														 2, 
														 &kCFTypeDictionaryKeyCallBacks, 
														 &kCFTypeDictionaryValueCallBacks);
            }
		
	}
	return sSharedInstance;
}

- (void) dealloc {	
	[super dealloc];
}

- (int)row {
    return _row;
}

- (void)setRow:(int)value {
	_row = value;
}

- (int)column {
    return _column;
}

- (void)setColumn:(int)value {
    _column = value;
}

- (int)cellWidth {
    return _cellWidth;
}

- (void)setCellWidth:(int)value {
    _cellWidth = value;
}

- (int)cellHeight {
    return _cellHeight;
}

- (void)setCellHeight:(int)value {
    _cellHeight = value;
}

- (NSColor *) colorAtIndex: (int) i hilite: (BOOL) h {
	if (i >= 0 && i < NUM_COLOR) 
		return _colorTable[h][i];
	return _colorTable[0][NUM_COLOR - 1];
}

- (void) setColor: (NSColor *) c hilite: (BOOL) h atIndex: (int) i {
	if (i >= 0 && i < NUM_COLOR) {
		[_colorTable[h][i] autorelease];
		_colorTable[h][i] = [c retain];
	}
}

- (BOOL)showHiddenText {
    return _showHiddenText;
}

- (void)setShowHiddenText:(BOOL)value {
    _showHiddenText = value;
    [[NSUserDefaults standardUserDefaults] setBool: value forKey: @"ShowHiddenText"];
}

- (BOOL)shouldSmoothFonts {
    return _shouldSmoothFonts;
}

- (void)setShouldSmoothFonts:(BOOL)value {
    _shouldSmoothFonts = value;
    [[NSUserDefaults standardUserDefaults] setBool: value forKey: @"ShouldSmoothFonts"];
}

- (BOOL)detectDoubleByte {
    return _detectDoubleByte;
}

- (void)setDetectDoubleByte:(BOOL)value {
    _detectDoubleByte = value;
    [[NSUserDefaults standardUserDefaults] setBool: value forKey: @"DetectDoubleByte"];
}

- (BOOL)blinkTicker {
    return _blinkTicker;
}

- (void)setBlinkTicker:(BOOL)value {
    _blinkTicker = value;
}
- (void)updateBlinkTicker {
    [self setBlinkTicker: !_blinkTicker];
}

- (NSArray *) encodingArray {
    return gEncodingArray;
}
- (void) setEncodingArray: (NSArray *) a {}
@end
