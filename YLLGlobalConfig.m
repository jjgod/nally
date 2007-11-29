//
//  YLLGlobalConfig.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/11/12.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLLGlobalConfig.h"

static YLLGlobalConfig *sSharedInstance;

@implementation YLLGlobalConfig
+ (YLLGlobalConfig*) sharedInstance {
	return sSharedInstance ?: [[YLLGlobalConfig new] autorelease];
}

- (id) init {
	if(sSharedInstance) {
		[self release];
	} else if(self = sSharedInstance = [[super init] retain]) {
		/* init code */
		_row = 24;
		_column = 80;
		_cellWidth = 12;
		_cellHeight = 24;
		[self setEFont: [NSFont fontWithName: @"Monaco" size: 18]];
		[self setCFont: [NSFont fontWithName: @"Hiragino Kaku Gothic Pro" size: 22]];
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
//		_colorTable[0][9] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.15 alpha: 1.0] retain];
//		_colorTable[1][9] = [[NSColor colorWithDeviceRed: 0.00 green: 0.00 blue: 0.15 alpha: 1.0] retain];

		_bitmapColorTable[0][0] = 0x00000000;
		_bitmapColorTable[1][0] = 0x40404000;
		_bitmapColorTable[0][1] = 0x80000000;
		_bitmapColorTable[1][1] = 0xFF000000;
		_bitmapColorTable[0][2] = 0x00800000;
		_bitmapColorTable[1][2] = 0x00FF0000;
		_bitmapColorTable[0][3] = 0x80800000;
		_bitmapColorTable[1][3] = 0xFFFF0000;
		_bitmapColorTable[0][4] = 0x00008000;
		_bitmapColorTable[1][4] = 0x0000FF00;
		_bitmapColorTable[0][5] = 0x80008000;
		_bitmapColorTable[1][5] = 0xFF00FF00;
		_bitmapColorTable[0][6] = 0x00808000;
		_bitmapColorTable[1][6] = 0x00FFFF00;
		_bitmapColorTable[0][7] = 0x80808000;
		_bitmapColorTable[1][7] = 0xFFFFFF00;
		_bitmapColorTable[0][8] = 0xC0C0C000;
		_bitmapColorTable[1][8] = 0xFFFFFF00;
		_bitmapColorTable[0][9] = 0x00000000;
		_bitmapColorTable[1][9] = 0x00000000;
		
		int i, j;
		ATSUFontID cATSUFontID, eATSUFontID;
		char *cATSUFontName = "STHeiti", *eATSUFontName = "Monaco";
		ATSUAttributeTag		tags[2];
		ByteCount				sizes[2];
		ATSUAttributeValuePtr	values[2];
		
		ATSUFindFontFromName(cATSUFontName, strlen(cATSUFontName), kFontFullName, kFontNoPlatform, kFontNoScript, kFontNoLanguage, &cATSUFontID);
		ATSUFindFontFromName(eATSUFontName, strlen(eATSUFontName), kFontFullName, kFontNoPlatform, kFontNoScript, kFontNoLanguage, &eATSUFontID);

		_cCTFont = CTFontCreateWithPlatformFont(cATSUFontID, 22.0, NULL, NULL);
		_eCTFont = CTFontCreateWithPlatformFont(eATSUFontID, 18.0, NULL, NULL);
		_cCGFont = CTFontCopyGraphicsFont(_cCTFont, NULL);
		_eCGFont = CTFontCopyGraphicsFont(_eCTFont, NULL);
		
		for (i = 0; i < NUM_COLOR; i++) 
			for (j = 0; j < 2; j++) {
				_cDictTable[j][i] = [[NSDictionary dictionaryWithObjectsAndKeys: _colorTable[j][i], NSForegroundColorAttributeName,
									  _cFont, NSFontAttributeName, nil] retain];
				_eDictTable[j][i] = [[NSDictionary dictionaryWithObjectsAndKeys: _colorTable[j][i], NSForegroundColorAttributeName,
									  _eFont, NSFontAttributeName, nil] retain];

				
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
				
				/* ---------- Chinese Style ---------- */
				ATSUCreateStyle( &(_cATSUStyle[j][i]));
				/* Font */
				tags[0] = kATSUFontTag;
				sizes[0] = sizeof(ATSUFontID);
				values[0] = &cATSUFontID;
				ATSUSetAttributes(_cATSUStyle[j][i], 1, tags, sizes, values);
				
				/* Size */
				Fixed pointSize = Long2Fix(22);
				tags[0] = kATSUSizeTag;
				sizes[0] = sizeof(Fixed);
				values[0] = &pointSize;
				ATSUSetAttributes(_cATSUStyle[j][i], 1, tags, sizes, values);
				
				/* Color */
				ATSURGBAlphaColor color;
				color.red = [_colorTable[j][i] redComponent];
				color.green = [_colorTable[j][i] greenComponent];
				color.blue = [_colorTable[j][i] blueComponent];
				color.alpha = 1.0;
				tags[0] = kATSURGBAlphaColorTag;
				sizes[0] = sizeof(ATSURGBAlphaColor);
				values[0] = &color;
				ATSUSetAttributes(_cATSUStyle[j][i], 1, tags, sizes, values);
				
				/* Fixed-Width */
				ATSUTextMeasurement glyphWidth = Long2Fix(12);
				tags[0] = kATSUImposeWidthTag;
				sizes[0] = sizeof(ATSUTextMeasurement);
				values[0] = &glyphWidth;
				ATSUSetAttributes(_cATSUStyle[j][i], 1, tags, sizes, values);

				/* ---------- English Style ---------- */
				ATSUCreateStyle( &(_eATSUStyle[j][i]));
				/* Font */
				tags[0] = kATSUFontTag;
				sizes[0] = sizeof(ATSUFontID);
				values[0] = &eATSUFontID;
				ATSUSetAttributes(_eATSUStyle[j][i], 1, tags, sizes, values);
				
				/* Size */
				pointSize = Long2Fix(18);
				tags[0] = kATSUSizeTag;
				sizes[0] = sizeof(Fixed);
				values[0] = &pointSize;
				ATSUSetAttributes(_eATSUStyle[j][i], 1, tags, sizes, values);
				
				/* Color */
				color.red = [_colorTable[j][i] redComponent];
				color.green = [_colorTable[j][i] greenComponent];
				color.blue = [_colorTable[j][i] blueComponent];
				color.alpha = 1.0;
				tags[0] = kATSURGBAlphaColorTag;
				sizes[0] = sizeof(ATSURGBAlphaColor);
				values[0] = &color;
				ATSUSetAttributes(_eATSUStyle[j][i], 1, tags, sizes, values);
				
				/* Fixed-Width */
				glyphWidth = Long2Fix(12);
				tags[0] = kATSUImposeWidthTag;
				sizes[0] = sizeof(ATSUTextMeasurement);
				values[0] = &glyphWidth;
				ATSUSetAttributes(_eATSUStyle[j][i], 1, tags, sizes, values);
			}
		
	}
	return sSharedInstance;
}

- (void) dealloc {
	[_eFont release];
	[_cFont release];
	
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

- (NSFont *)eFont {
    return [[_eFont retain] autorelease];
}

- (void)setEFont:(NSFont *)value {
    if (_eFont != value) {
        [_eFont release];
        _eFont = [value copy];
    }
}

- (NSFont *)cFont {
    return [[_cFont retain] autorelease];
}

- (void)setCFont:(NSFont *)value {
    if (_cFont != value) {
        [_cFont release];
        _cFont = [value copy];
    }
}

- (NSColor *) colorAtIndex: (int) i hilite: (BOOL) h {
	if (i >= 0 && i < NUM_COLOR) 
		return _colorTable[h][i];
	return _colorTable[0][NUM_COLOR - 1];
}

- (unsigned short) bitmapColorAtIndex: (int) i hilite: (BOOL) h {
	if (i >= 0 && i < NUM_COLOR) 
		return _bitmapColorTable[h][i];
	return _bitmapColorTable[0][NUM_COLOR - 1];
}


- (void) setColor: (NSColor *) c hilite: (BOOL) h atIndex: (int) i {
	if (i >= 0 && i < NUM_COLOR) {
		[_colorTable[h][i] autorelease];
		_colorTable[h][i] = [c retain];
	}
}

- (NSDictionary *) cFontAttributeForColorIndex: (int) i hilite: (BOOL) h {
	return _cDictTable[h][i];
}

- (NSDictionary *) eFontAttributeForColorIndex: (int) i hilite: (BOOL) h {
	return _eDictTable[h][i];
}

- (BOOL)showHiddenText {
    return _showHiddenText;
}

- (void)setShowHiddenText:(BOOL)value {
    _showHiddenText = value;
    [[NSUserDefaults standardUserDefaults] setBool: value forKey: @"ShowHiddenText"];
}

@end
