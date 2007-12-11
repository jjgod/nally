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

@interface NSUserDefaults(myColorSupport)
- (void)setMyColor:(NSColor *)aColor forKey:(NSString *)aKey;
- (NSColor *)myColorForKey:(NSString *)aKey;
@end
@implementation NSUserDefaults(myColorSupport)

- (void)setMyColor:(NSColor *)aColor forKey:(NSString *)aKey {
    NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
    [self setObject:theData forKey:aKey];
}

- (NSColor *)myColorForKey:(NSString *)aKey {
    NSColor *theColor=nil;
    NSData *theData=[self dataForKey:aKey];
    if (theData != nil)
        theColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
    return theColor;
}
@end

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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [self setShowHiddenText: [defaults boolForKey: @"ShowHiddenText"]];
        [self setShouldSmoothFonts: [defaults boolForKey: @"ShouldSmoothFonts"]];
        [self setDetectDoubleByte: [defaults boolForKey: @"DetectDoubleByte"]];

		/* init code */
		_row = 24;
		_column = 80;
		_cellWidth = 12;
		_cellHeight = 24;

        [self setColorBlack: [defaults myColorForKey: @"ColorBlack"]];
        [self setColorBlackHilite: [defaults myColorForKey: @"ColorBlackHilite"]]; 
        [self setColorRed: [defaults myColorForKey: @"ColorRed"]];
        [self setColorRedHilite: [defaults myColorForKey: @"ColorRedHilite"]]; 
        [self setColorBlack: [defaults myColorForKey: @"ColorBlack"]];
        [self setColorBlackHilite: [defaults myColorForKey: @"ColorBlackHilite"]]; 
        [self setColorGreen: [defaults myColorForKey: @"ColorGreen"]];
        [self setColorGreenHilite: [defaults myColorForKey: @"ColorGreenHilite"]]; 
        [self setColorYellow: [defaults myColorForKey: @"ColorYellow"]];
        [self setColorYellowHilite: [defaults myColorForKey: @"ColorYellowHilite"]]; 
        [self setColorBlue: [defaults myColorForKey: @"ColorBlue"]];
        [self setColorBlueHilite: [defaults myColorForKey: @"ColorBlueHilite"]]; 
        [self setColorMagenta: [defaults myColorForKey: @"ColorMagenta"]];
        [self setColorMagentaHilite: [defaults myColorForKey: @"ColorMagentaHilite"]]; 
        [self setColorCyan: [defaults myColorForKey: @"ColorCyan"]];
        [self setColorCyanHilite: [defaults myColorForKey: @"ColorCyanHilite"]]; 
        [self setColorWhite: [defaults myColorForKey: @"ColorWhite"]];
        [self setColorWhiteHilite: [defaults myColorForKey: @"ColorWhiteHilite"]]; // Foreground Color
        [self setColorBG: [defaults myColorForKey: @"ColorBG"]];
        [self setColorBGHilite: [defaults myColorForKey: @"ColorBGHilite"]]; 
        _colorTable[0][8] = [[NSColor colorWithDeviceRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];
        _colorTable[1][8] = [[NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 1.00 alpha: 1.0] retain];

        _bgColorIndex = 9;
        _fgColorIndex = 7;
        
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
		_colorTable[h][i] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
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

#pragma mark -
#pragma mark Colors
- (NSColor *) colorBlack { return _colorTable[0][0]; }
- (void) setColorBlack: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[0][0]) {
        [_colorTable[0][0] release];
        _colorTable[0][0] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorBlack"];
}
- (NSColor *) colorBlackHilite { return _colorTable[1][0]; }
- (void) setColorBlackHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.25 green: 0.25 blue: 0.25 alpha: 1.0];
    if (c != _colorTable[1][0]) {
        [_colorTable[1][0] release];
        _colorTable[1][0] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorBlackHilite"];
}

- (NSColor *) colorRed { return _colorTable[0][1]; }
- (void) setColorRed: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.50 green: 0.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[0][1]) {
        [_colorTable[0][1] release];
        _colorTable[0][1] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorRed"];
}
- (NSColor *) colorRedHilite { return _colorTable[1][1]; }
- (void) setColorRedHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 1.00 green: 0.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[1][1]) {
        [_colorTable[1][1] release];
        _colorTable[1][1] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorRedHilite"];
}

- (NSColor *) colorGreen { return _colorTable[0][2]; }
- (void) setColorGreen: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.50 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[0][2]) {
        [_colorTable[0][2] release];
        _colorTable[0][2] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorGreen"];
}
- (NSColor *) colorGreenHilite { return _colorTable[1][2]; }
- (void) setColorGreenHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 1.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[1][2]) {
        [_colorTable[1][2] release];
        _colorTable[1][2] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorGreenHilite"];
}

- (NSColor *) colorYellow { return _colorTable[0][3]; }
- (void) setColorYellow: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.50 green: 0.50 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[0][3]) {
        [_colorTable[0][3] release];
        _colorTable[0][3] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorYellow"];
}
- (NSColor *) colorYellowHilite { return _colorTable[1][3]; }
- (void) setColorYellowHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[1][3]) {
        [_colorTable[1][3] release];
        _colorTable[1][3] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorYellowHilite"];
}

- (NSColor *) colorBlue { return _colorTable[0][4]; }
- (void) setColorBlue: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.50 alpha: 1.0];
    if (c != _colorTable[0][4]) {
        [_colorTable[0][4] release];
        _colorTable[0][4] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorBlue"];
}
- (NSColor *) colorBlueHilite { return _colorTable[1][4]; }
- (void) setColorBlueHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 1.00 alpha: 1.0];
    if (c != _colorTable[1][4]) {
        [_colorTable[1][4] release];
        _colorTable[1][4] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorBlueHilite"];
}

- (NSColor *) colorMagenta { return _colorTable[0][5]; }
- (void) setColorMagenta: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.50 green: 0.00 blue: 0.50 alpha: 1.0];
    if (c != _colorTable[0][5]) {
        [_colorTable[0][5] release];
        _colorTable[0][5] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorMagenta"];
}
- (NSColor *) colorMagentaHilite { return _colorTable[1][5]; }
- (void) setColorMagentaHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 1.00 green: 0.00 blue: 1.00 alpha: 1.0];
    if (c != _colorTable[1][5]) {
        [_colorTable[1][5] release];
        _colorTable[1][5] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorMagentaHilite"];
}

- (NSColor *) colorCyan { return _colorTable[0][6]; }
- (void) setColorCyan: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.50 blue: 0.50 alpha: 1.0];
    if (c != _colorTable[0][6]) {
        [_colorTable[0][6] release];
        _colorTable[0][6] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorCyan"];
}
- (NSColor *) colorCyanHilite { return _colorTable[1][6]; }
- (void) setColorCyanHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 1.00 blue: 1.00 alpha: 1.0];
    if (c != _colorTable[1][6]) {
        [_colorTable[1][6] release];
        _colorTable[1][6] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorCyanHilite"];
}

- (NSColor *) colorWhite { return _colorTable[0][7]; }
- (void) setColorWhite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.50 green: 0.50 blue: 0.50 alpha: 1.0];
    if (c != _colorTable[0][7]) {
        [_colorTable[0][7] release];
        _colorTable[0][7] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorWhite"];
}
- (NSColor *) colorWhiteHilite { return _colorTable[1][7]; }
- (void) setColorWhiteHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 1.00 green: 1.00 blue: 1.00 alpha: 1.0];
    if (c != _colorTable[1][7]) {
        [_colorTable[1][7] release];
        _colorTable[1][7] = [c retain];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorWhiteHilite"];
}

- (NSColor *) colorBG { return _colorTable[0][9]; }
- (void) setColorBG: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[0][9]) {
        [_colorTable[0][9] release];
        _colorTable[0][9] = [[c colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
//        if ([self colorBGHilite] != c) [self setColorBGHilite: c];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorBG"];
}
- (NSColor *) colorBGHilite { return _colorTable[1][9]; }
- (void) setColorBGHilite: (NSColor *) c {
    if (!c) c = [NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.00 alpha: 1.0];
    if (c != _colorTable[1][9]) {
        [_colorTable[1][9] release];
        _colorTable[1][9] = [c retain];
//        if ([self colorBG] != c) [self setColorBG: c];
    }
    [[NSUserDefaults standardUserDefaults] setMyColor: c forKey: @"ColorBGHilite"];
}
@end
