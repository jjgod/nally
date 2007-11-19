//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLView.h"
#import "YLTerminal.h"
#import "encoding.h"
#import "YLTelnet.h"
#import "YLLGLobalConfig.h"
#import "YLMarkedTextView.h"

static YLLGlobalConfig *gConfig;
static int gRow;
static int gColumn;
static NSImage *gLeftImage;
static CGSize *gSingleAdvance;
static CGSize *gDoubleAdvance;
static NSCharacterSet *gBopomofoCharSet = nil;


static NSRect gSymbolBlackSquareRect;
static NSRect gSymbolBlackSquareRect1;
static NSRect gSymbolBlackSquareRect2;
static NSRect gSymbolLowerBlockRect[8];
static NSRect gSymbolLowerBlockRect1[8];
static NSRect gSymbolLowerBlockRect2[8];
static NSRect gSymbolLeftBlockRect[7];
static NSRect gSymbolLeftBlockRect1[7];
static NSRect gSymbolLeftBlockRect2[7];
static NSBezierPath *gSymbolTrianglePath[4];
static NSBezierPath *gSymbolTrianglePath1[4];
static NSBezierPath *gSymbolTrianglePath2[4];

BOOL isSpecialSymbol(unichar ch) {
	if (ch == 0x25FC)  // ◼ BLACK SQUARE
		return YES;
	if (ch >= 0x2581 && ch <= 0x2588) // BLOCK ▁▂▃▄▅▆▇█
		return YES;
	if (ch >= 0x2589 && ch <= 0x258F) // BLOCK ▉▊▋▌▍▎▏
		return YES;
	if (ch >= 0x25E2 && ch <= 0x25E5) // TRIANGLE ◢◣◤◥
		return YES;
	return NO;
}

@implementation YLView

- (void) createSymbolPath {
	int i = 0;
	gSymbolBlackSquareRect = NSMakeRect(1.0, 1.0, _fontWidth * 2 - 2, _fontHeight - 2);
	gSymbolBlackSquareRect1 = NSMakeRect(1.0, 1.0, _fontWidth - 1, _fontHeight - 2); 
	gSymbolBlackSquareRect2 = NSMakeRect(_fontWidth, 1.0, _fontWidth - 1, _fontHeight - 2);
	
	for (i = 0; i < 8; i++) {
		gSymbolLowerBlockRect[i] = NSMakeRect(0.0, 0.0, _fontWidth * 2, _fontHeight * (i + 1) / 8);
        gSymbolLowerBlockRect1[i] = NSMakeRect(0.0, 0.0, _fontWidth, _fontHeight * (i + 1) / 8);
        gSymbolLowerBlockRect2[i] = NSMakeRect(_fontWidth, 0.0, _fontWidth, _fontHeight * (i + 1) / 8);
	}
    
    for (i = 0; i < 7; i++) {
        gSymbolLeftBlockRect[i] = NSMakeRect(0.0, 0.0, _fontWidth * (7 - i) / 4, _fontHeight);
        gSymbolLeftBlockRect1[i] = NSMakeRect(0.0, 0.0, (7 - i >= 4) ? _fontWidth : (_fontWidth * (7 - i) / 4), _fontHeight);
        gSymbolLeftBlockRect2[i] = NSMakeRect(_fontWidth, 0.0, (7 - i <= 4) ? 0.0 : (_fontWidth * (3 - i) / 4), _fontHeight);
    }
    
    NSPoint pts[6] = {
        NSMakePoint(_fontWidth, 0.0),
        NSMakePoint(0.0, 0.0),
        NSMakePoint(0.0, _fontHeight),
        NSMakePoint(_fontWidth, _fontHeight),
        NSMakePoint(_fontWidth * 2, _fontHeight),
        NSMakePoint(_fontWidth * 2, 0.0),
    };
    int triangleIndex[4][3] = { {1, 4, 5}, {1, 2, 5}, {1, 2, 4}, {2, 4, 5} };

    int triangleIndex1[4][3] = { {0, 1, -1}, {0, 1, 2}, {1, 2, 3}, {2, 3, -1} };
    int triangleIndex2[4][3] = { {4, 5, 0}, {5, 0, -1}, {3, 4, -1}, {3, 4, 5} };
    
    int base = 0;
    for (base = 0; base < 4; base++) {
        if (gSymbolTrianglePath[base]) 
            [gSymbolTrianglePath[base] release];
        gSymbolTrianglePath[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePath[base] moveToPoint: pts[triangleIndex[base][0]]];
        for (i = 1; i < 3; i ++)
            [gSymbolTrianglePath[base] lineToPoint: pts[triangleIndex[base][i]]];
        [gSymbolTrianglePath[base] closePath];
        
        if (gSymbolTrianglePath1[base])
            [gSymbolTrianglePath1[base] release];
        gSymbolTrianglePath1[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePath1[base] moveToPoint: NSMakePoint(_fontWidth, _fontHeight / 2)];
        for (i = 0; i < 3 && triangleIndex1[base][i] >= 0; i++)
            [gSymbolTrianglePath1[base] lineToPoint: pts[triangleIndex1[base][i]]];
        [gSymbolTrianglePath1[base] closePath];
        
        if (gSymbolTrianglePath2[base])
            [gSymbolTrianglePath2[base] release];
        gSymbolTrianglePath2[base] = [[NSBezierPath alloc] init];
        [gSymbolTrianglePath2[base] moveToPoint: NSMakePoint(_fontWidth, _fontHeight / 2)];
        for (i = 0; i < 3 && triangleIndex2[base][i] >= 0; i++)
            [gSymbolTrianglePath2[base] lineToPoint: pts[triangleIndex2[base][i]]];
        [gSymbolTrianglePath2[base] closePath];
    }
}

- (id)initWithFrame:(NSRect)frame {
	if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
	gColumn = [gConfig column];
	gRow = [gConfig row];
	if (!gBopomofoCharSet) 
		gBopomofoCharSet = [[NSCharacterSet characterSetWithCharactersInString: 
							[NSString stringWithUTF8String: "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦ【】、"]] retain];
	
	
	
	frame.size = NSMakeSize(gColumn * [gConfig cellWidth], gRow * [gConfig cellHeight]);
    self = [super initWithFrame: frame];
    if (self) {
		_fontWidth = [gConfig cellWidth];
		_fontHeight = [gConfig cellHeight];
        [self createSymbolPath];
		
        _selectionLength = 0;
        _selectionLocation = 0;
        
		_backedImage = [[NSImage alloc] initWithSize: frame.size];
		[_backedImage setFlipped: NO];
		[_backedImage lockFocus];
		[[gConfig colorAtIndex: 9 hilite: NO] set];
		[NSBezierPath fillRect: NSMakeRect(0, 0, frame.size.width, frame.size.height)];
		[_backedImage unlockFocus];

		if (!gLeftImage) {
			gLeftImage = [[NSImage alloc] initWithSize: NSMakeSize(_fontWidth, _fontHeight)];
			[gLeftImage setFlipped: YES];			
		}
		gSingleAdvance = (CGSize *) malloc(sizeof(CGSize) * gColumn);
		gDoubleAdvance = (CGSize *) malloc(sizeof(CGSize) * gColumn);
		int i;
		for (i = 0; i < gColumn; i++) {
			gSingleAdvance[i] = CGSizeMake(_fontWidth * 1.0, 0.0);
			gDoubleAdvance[i] = CGSizeMake(_fontWidth * 2.0, 0.0);
		}
		_markedText = nil;
		_selectedRange = NSMakeRange(NSNotFound, 0);
		_markedRange = NSMakeRange(NSNotFound, 0);
		[_textField setHidden: YES];
    }
    return self;
}

- (void) dealloc {
	[_backedImage release];
	[super dealloc];
}

#pragma mark -
#pragma mark Actions

- (void) copy: (id) sender {
    if (![self connected]) return;
    if (_selectionLength == 0) return;
    int location, length;
    if (_selectionLength >= 0) {
        location = _selectionLocation;
        length = _selectionLength;
    } else {
        location = _selectionLocation + _selectionLength;
        length = 0 - (int)_selectionLength;
    }
    
    NSString *s = [[self dataSource] stringFromIndex: location length: length];
    if (s) {
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        NSArray *types = [NSArray arrayWithObjects: NSStringPboardType, nil];
        [pb declareTypes:types owner:self];
        [pb setString: s forType:NSStringPboardType];        
    }
}

- (void) paste: (id) sender {
    if (![self connected]) return;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [pb types];
    if ([types containsObject: NSStringPboardType]) {
        NSString *str = [pb stringForType: NSStringPboardType];
        NSMutableString *mStr = [NSMutableString stringWithString: str];
        [mStr replaceOccurrencesOfString: @"\n"
                              withString: @"\r"
                                 options: NSLiteralSearch
                                   range: NSMakeRange(0, [str length])];
        [self insertText: mStr];
    }
}

- (void) selectAll: (id) sender {
    if (![self connected]) return;
    _selectionLocation = 0;
    _selectionLength = gRow * gColumn;
    [self setNeedsDisplay: YES];
}

- (BOOL) validateMenuItem: (NSMenuItem *) item {
    if ([item action] == @selector(copy:) && (![self connected] || _selectionLength == 0)) {
        return NO;
    } else if ([item action] == @selector(paste:) && ![self connected]) {
        return NO;
    } else if ([item action] == @selector(selectAll:)  && ![self connected]) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Conversion

- (int) convertPointToIndex: (NSPoint) p {
    if (p.x >= gColumn * _fontWidth) p.x = gColumn * _fontWidth - 0.001;
    if (p.y >= gRow * _fontHeight) p.y = gRow * _fontHeight - 0.001;
    if (p.x < 0) p.x = 0;
    if (p.y < 0) p.y = 0;
    int cx, cy = 0;
    cx = ((int)p.x) / _fontWidth;
    cy = gRow - (((int)p.y) / _fontHeight) - 1;
    return cy * gColumn + cx;
}


#pragma mark -
#pragma mark Event Handling
- (void) mouseDown: (NSEvent *) e {
    [[self window] makeFirstResponder: self];
    if (![self connected]) return;
    NSPoint p = [e locationInWindow];
    p = [self convertPoint: p toView: nil];
    _selectionLocation = [self convertPointToIndex: p];
    _selectionLength = 0;
    [self setNeedsDisplay: YES];
}

- (void) mouseDragged: (NSEvent *) e {
    if (![self connected]) return;
    NSPoint p = [e locationInWindow];
    p = [self convertPoint: p toView: nil];
    int index = [self convertPointToIndex: p];
    int oldValue = _selectionLength;
    _selectionLength = index - _selectionLocation + 1;
    if (_selectionLength <= 0) _selectionLength--;
    if (oldValue != _selectionLength)
        [self setNeedsDisplay: YES];
}

- (void) mouseUp: (NSEvent *) e {
    if (![self connected]) return;
    if (_selectionLength == 0) {
        NSPoint p = [e locationInWindow];
        p = [self convertPoint: p toView: nil];
        int index = [self convertPointToIndex: p];
        int r = index / gColumn;
        int c = index % gColumn;
        cell *currRow = [[self dataSource] cellsOfRow: r];
        if (currRow[c].attr.f.url) {
            int start = c;
            for (start = c; start >= 0 && currRow[start].attr.f.url; start--) ;
            start++;
            int end = c;
            for (end = c; end < gColumn && currRow[end].attr.f.url; end++) ;

            NSMutableString *url = [NSMutableString string];
            for (c = start; c < end; c++)
                [url appendFormat: @"%c", currRow[c].byte];
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
        }
    }
}

- (void) keyDown: (NSEvent *) e {
	unichar c = [[e characters] characterAtIndex: 0];
	unsigned char arrow[3] = {0x1B, 0x4F, 0x00};
	unsigned char buf[10];
//	NSLog(@"%02X %02X", [[e characters] characterAtIndex: 0], c);

	if ([e modifierFlags] & NSControlKeyMask) {
		buf[0] = c;
		[[self telnet] sendBytes: buf length: 1];
	}
	
	if (c == NSUpArrowFunctionKey) arrow[2] = 'A';
	if (c == NSDownArrowFunctionKey) arrow[2] = 'B';
	if (c == NSRightArrowFunctionKey) arrow[2] = 'C';
	if (c == NSLeftArrowFunctionKey) arrow[2] = 'D';
	
	if (![self hasMarkedText] && 
		(c == NSUpArrowFunctionKey ||
		 c == NSDownArrowFunctionKey ||
		 c == NSRightArrowFunctionKey || 
		 c == NSLeftArrowFunctionKey)) {
		[[self telnet] sendBytes: arrow length: 3];
		return;
	}
	
	if (![self hasMarkedText] && (c == 0x7F || c == NSDeleteFunctionKey)) {
		buf[0] = 0x08;
		[[self telnet] sendBytes: buf length: 1];
        return;
	}
//	
//	unsigned char ch = (unsigned char) c;
//	[_telnet sendBytes: &ch length: 1];
	[self interpretKeyEvents: [NSArray arrayWithObject: e]];
}

#pragma mark -
#pragma mark Drawing

- (void) tick: (NSTimer *) t {
	[self update];
    YLTerminal *ds = [self dataSource];
	if (_x != ds->_cursorX || _y != ds->_cursorY) {
		[self setNeedsDisplayInRect: NSMakeRect(_x * _fontWidth, (gRow - 1 - _y) * _fontHeight, _fontWidth, _fontHeight)];
		[self setNeedsDisplayInRect: NSMakeRect(ds->_cursorX * _fontWidth, (gRow - 1 - ds->_cursorY) * _fontHeight, _fontWidth, _fontHeight)];
		_x = ds->_cursorX;
		_y = ds->_cursorY;
	}
}

- (NSRect) cellRectForRect: (NSRect) r {
	int originx = r.origin.x / _fontWidth;
	int originy = r.origin.y / _fontHeight;
	int width = ((r.size.width + r.origin.x) / _fontWidth) - originx + 1;
	int height = ((r.size.height + r.origin.y) / _fontHeight) - originy + 1;
	return NSMakeRect(originx, originy, width, height);
}

- (void)drawRect:(NSRect)rect {
    YLTerminal *ds = [self dataSource];
	if ([self connected]) {
		NSRect imgRect = rect;
		imgRect.origin.y = (_fontHeight * gRow) - rect.origin.y - rect.size.height;
		[_backedImage compositeToPoint: rect.origin
							  fromRect: rect
							 operation: NSCompositeCopy];

        [[NSColor orangeColor] set];
        [NSBezierPath setDefaultLineWidth: 1.0];
        /* Draw the url underline */
        int c, r;
        for (r = 0; r < gColumn; r++) {
            [ds updateURLStateForRow: r];
            cell *currRow = [ds cellsOfRow: r];
            for (c = 0; c < gColumn; c++) {
                int start;
                for (start = c; currRow[c].attr.f.url && c < gColumn; c++) ;
                if (c != start) {
                    [NSBezierPath strokeLineFromPoint: NSMakePoint(start * _fontWidth + 0.5, (gRow - r - 1) * _fontHeight + 0.5) 
                                              toPoint: NSMakePoint(c * _fontWidth - 0.5, (gRow - r - 1) * _fontHeight + 0.5)];
                }
            }
        }
		/* Draw the cursor */
		
		[[NSColor whiteColor] set];
		[NSBezierPath setDefaultLineWidth: 2.0];
		[NSBezierPath strokeLineFromPoint: NSMakePoint(ds->_cursorX * _fontWidth, (gRow - 1 - ds->_cursorY) * _fontHeight + 1) 
								  toPoint: NSMakePoint((ds->_cursorX + 1) * _fontWidth, (gRow - 1 - ds->_cursorY) * _fontHeight + 1) ];
        [NSBezierPath setDefaultLineWidth: 1.0];
		/* Draw the input buffer */
		
        if (_selectionLength != 0) 
            [self drawSelection];
        
	} else {
		[[gConfig colorAtIndex: NUM_COLOR - 1 hilite: 0] set];
		[NSBezierPath fillRect: [self bounds]];
	}
	
//	int x, y;
//	[[NSColor whiteColor] set];
//	for (y = 0; y < gRow; y++) 
//		[NSBezierPath strokeLineFromPoint: NSMakePoint(0, y * _fontHeight + 0.5) toPoint: NSMakePoint(gColumn * _fontWidth, y * _fontHeight + 0.5)];
//	for (x = 0; x < gColumn; x++) 
//		[NSBezierPath strokeLineFromPoint: NSMakePoint(x * _fontWidth + 0.5, 0) toPoint: NSMakePoint(x * _fontWidth + 0.5, gRow * _fontHeight)];	

}

- (void) drawSelection {
    int location, length;
    if (_selectionLength >= 0) {
        location = _selectionLocation;
        length = _selectionLength;
    } else {
        location = _selectionLocation + _selectionLength;
        length = 0 - (int)_selectionLength;
    }
    int x = location % gColumn;
    int y = location / gColumn;
    [[NSColor colorWithCalibratedRed: 0.6 green: 0.9 blue: 0.6 alpha: 0.4] set];

    while (length > 0) {
        if (x + length <= gColumn) { // one-line
            [NSBezierPath fillRect: NSMakeRect(x * _fontWidth, (gRow - y - 1) * _fontHeight, _fontWidth * length, _fontHeight)];
            length = 0;
        } else {
            [NSBezierPath fillRect: NSMakeRect(x * _fontWidth, (gRow - y - 1) * _fontHeight, _fontWidth * (gColumn - x), _fontHeight)];
            length -= (gColumn - x);
        }
        x = 0;
        y++;
    }
}

- (void) clearScreen: (int) opt atRow: (int) r column: (int) c {
	
}

/* 
	Extend Bottom:
 
		AAAAAAAAAAA			BBBBBBBBBBB
		BBBBBBBBBBB			CCCCCCCCCCC
		CCCCCCCCCCC   ->	DDDDDDDDDDD
		DDDDDDDDDDD			...........
 
 */
- (void) extendBottom {
	[_backedImage lockFocus];
	[_backedImage compositeToPoint: NSMakePoint(0, _fontHeight) 
						  fromRect: NSMakeRect(0, 0, gColumn * _fontWidth, (gRow - 1) * _fontHeight) 
						 operation: NSCompositeCopy];

	[gConfig->_colorTable[0][NUM_COLOR - 1] set];
	[NSBezierPath fillRect: NSMakeRect(0, 0, gColumn * _fontWidth, _fontHeight)];
	[_backedImage unlockFocus];
}


/* 
	Extend Top:
 
		AAAAAAAAAAA			...........
		BBBBBBBBBBB			AAAAAAAAAAA
		CCCCCCCCCCC   ->	BBBBBBBBBBB
		DDDDDDDDDDD			CCCCCCCCCCC
 */
- (void) extendTop {
	[_backedImage lockFocus];
	[_backedImage compositeToPoint: NSMakePoint(0, 0) 
						  fromRect: NSMakeRect(0, _fontHeight, gColumn * _fontWidth, (gRow - 1) * _fontHeight) 
						 operation: NSCompositeCopy];
	
	[gConfig->_colorTable[0][NUM_COLOR - 1] set];
	[NSBezierPath fillRect: NSMakeRect(0, (gRow - 1) * _fontHeight, gColumn * _fontWidth, _fontHeight)];
	[_backedImage unlockFocus];
}

- (void) update {
	int x, y;
    YLTerminal *ds = [self dataSource];
	[_backedImage lockFocus];
	CGContextRef myCGContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	
	/* Draw Background */
	for (y = 0; y < gRow; y++) {
		for (x = 0; x < gColumn; x++) {
			if ([ds isDirtyAtRow: y column: x]) {
				int startx = x;
				for (; x < gColumn && [ds isDirtyAtRow:y column:x]; x++) ;
				[self updateBackgroundForRow: y from: startx to: x];
			}
		}
	}
	CGContextSaveGState(myCGContext);
	CGContextSetShouldSmoothFonts(myCGContext, NO);

	/* Draw String row by row */
	for (y = 0; y < gRow; y++) {
		[self drawStringForRow: y context: myCGContext];
	}		
	CGContextRestoreGState(myCGContext);
	
	for (y = 0; y < gRow; y++) {
		for (x = 0; x < gColumn; x++) {
			[ds setDirty: NO atRow: y column: x];
		}
	}

	[_backedImage unlockFocus];
}

- (void) drawStringForRow: (int) r context: (CGContextRef) myCGContext {
	int i, c, x;
	int start, end;
	unichar textBuf[gColumn];
	BOOL isDoubleByte[gColumn];
	int bufIndex[gColumn];
	int runLength[gColumn];
	CGPoint position[gColumn];
	int bufLength = 0;
    YLTerminal *ds = [self dataSource];
    [ds updateDoubleByteStateForRow: r];
	
    cell *currRow = [ds cellsOfRow: r];

	for (i = 0; i < gColumn; i++) 
		isDoubleByte[i] = textBuf[i] = runLength[i] = 0;

	for (x = 0; x < gColumn && ![ds isDirtyAtRow: r column: x]; x++) ;
	start = x;
	if (start == gColumn) return;
	
	for (x = start; x < gColumn; x++) {
		if (![ds isDirtyAtRow: r column: x]) continue;
		end = x;
		int db = (currRow + x)->attr.f.doubleByte;

		if (db == 0) {
			isDoubleByte[bufLength] = NO;
			textBuf[bufLength] = 0x0000 + (currRow + x)->byte;
			bufIndex[bufLength] = x;
			position[bufLength] = CGPointMake(x * _fontWidth + 1.0, (gRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_eCTFont) + 2.0);
			bufLength++;
		} else if (db == 1) {
			continue;
		} else if (db == 2) {
			unichar ch = B2U[(((currRow + x - 1)->byte) << 8) + ((currRow + x)->byte) - 0x8000];
			if (isSpecialSymbol(ch)) {
				[self drawSpecialSymbol: ch forRow: r column: (x - 1) leftAttribute: (currRow + x - 1)->attr rightAttribute: (currRow + x)->attr];
				isDoubleByte[bufLength] = NO;
				isDoubleByte[bufLength + 1] = NO;
				textBuf[bufLength] = 0x3000;
				position[bufLength] = CGPointMake((x - 1) * _fontWidth + 2.0, (gRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_cCTFont) + 1.0);
				bufIndex[bufLength] = x;
				bufLength ++;
			} else {
				isDoubleByte[bufLength] = YES;
				textBuf[bufLength] = ch;
				bufIndex[bufLength] = x;
				position[bufLength] = CGPointMake((x - 1) * _fontWidth + 2.0, (gRow - 1 - r) * _fontHeight + CTFontGetDescent(gConfig->_cCTFont) + 2.0);
				bufLength++;
			}
			if (x == start)
				[self setNeedsDisplayInRect: NSMakeRect((x - 1) * _fontWidth, (gRow - 1 - r) * _fontHeight, _fontWidth, _fontHeight)];				
		}
	}
	
	CFStringRef str = CFStringCreateWithCharacters(kCFAllocatorDefault, textBuf, bufLength);
	CFAttributedStringRef attributedString = CFAttributedStringCreate(kCFAllocatorDefault, str, NULL);
	CFMutableAttributedStringRef mutableAttributedString = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, 0, attributedString);
	CFRelease(str);
	CFRelease(attributedString);
		
	/* Run-length of the style */
	c = 0;
	while (c < bufLength) {
		int location = c;
		int length = 0;
		BOOL db = isDoubleByte[c];

		attribute currAttr, lastAttr = (currRow + bufIndex[c])->attr;
		for (; c < bufLength; c++) {
			currAttr = (currRow + bufIndex[c])->attr;
			if (currAttr.v != lastAttr.v || isDoubleByte[c] != db) break;
		}
		length = c - location;
		
		CFDictionaryRef attr;
		if (db) 
			attr = gConfig->_cCTAttribute[lastAttr.f.bold][lastAttr.f.reverse ? lastAttr.f.bgColor : lastAttr.f.fgColor];
		else
			attr = gConfig->_eCTAttribute[lastAttr.f.bold][lastAttr.f.reverse ? lastAttr.f.bgColor : lastAttr.f.fgColor];
		
		CFAttributedStringSetAttributes(mutableAttributedString, CFRangeMake(location, length), attr, YES);
	}
	
	CTLineRef line = CTLineCreateWithAttributedString(mutableAttributedString);
	CFRelease(mutableAttributedString);
	
	CFIndex glyphCount = CTLineGetGlyphCount(line);
	if (glyphCount == 0) {
		CFRelease(line);
		return;
	}
	
	CFArrayRef runArray = CTLineGetGlyphRuns(line);
	CFIndex runCount = CFArrayGetCount(runArray);
	CFIndex glyphOffset = 0;
	
	CFIndex runIndex = 0;

	for (; runIndex < runCount; runIndex++) {
		CTRunRef run = (CTRunRef) CFArrayGetValueAtIndex(runArray,  runIndex);
		CFIndex runGlyphCount = CTRunGetGlyphCount(run);
		CFIndex runGlyphIndex = 0;

		CFDictionaryRef attrDict = CTRunGetAttributes(run);
		CTFontRef runFont = (CTFontRef)CFDictionaryGetValue(attrDict,  kCTFontAttributeName);
		CGFontRef cgFont = CTFontCopyGraphicsFont(runFont, NULL);
		NSColor *runColor = (NSColor *) CFDictionaryGetValue(attrDict, kCTForegroundColorAttributeName);
		
		CGContextSetFont(myCGContext, cgFont);
		CGContextSetFontSize(myCGContext, CTFontGetSize(runFont));
		CGContextSetRGBFillColor(myCGContext, 
								 [runColor redComponent], 
								 [runColor greenComponent], 
								 [runColor blueComponent], 
								 1.0);
		
		CGGlyph glyph[gColumn];
		CFRange glyphRange = CFRangeMake(runGlyphIndex, runGlyphCount);
		CTRunGetGlyphs(run, glyphRange, glyph);

		CGAffineTransform textMatrix = CTRunGetTextMatrix(run);
		textMatrix.tx = position[glyphOffset].x;
		textMatrix.ty = position[glyphOffset].y;
		CGContextSetTextMatrix(myCGContext, textMatrix);
		
		CGContextShowGlyphsWithAdvances(myCGContext, glyph, isDoubleByte[glyphOffset] ? gDoubleAdvance : gSingleAdvance, runGlyphCount);
		
/*		for (; runGlyphIndex < runGlyphCount; runGlyphIndex++) {
			CFRange glyphRange = CFRangeMake(runGlyphIndex, 1);
			CGGlyph glyph;
			CTRunGetGlyphs(run, glyphRange, &glyph);
			CGContextShowGlyphsAtPoint(myCGContext, position[runGlyphIndex + glyphOffset].x, position[runGlyphIndex + glyphOffset].y, &glyph, 1);
		}*/
		glyphOffset += runGlyphCount;
		CFRelease(cgFont);
	}
	
	CFRelease(line);
}

- (void) updateBackgroundForRow: (int) r from: (int) start to: (int) end {
	int c;
	cell *currRow = [[self dataSource] cellsOfRow: r];
	NSRect rowRect = NSMakeRect(start * _fontWidth, (gRow - 1 - r) * _fontHeight, (end - start) * _fontWidth, _fontHeight);

	attribute currAttr, lastAttr = (currRow + start)->attr;
	int length = 0;
	unsigned int currentBackgroundColor;
	unsigned int lastBackgroundColor = lastAttr.f.reverse ? lastAttr.f.fgColor : lastAttr.f.bgColor;
	
	/* TODO: optimize the number of fillRect method. */
	/* 
		for example: 
		
		  BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
		
		currently, we draw each color segment one by one, like this:
		
		1. BBBBBBBBBBB
		2. BBBBBBBBBBBWWWWWWWWWW
		3. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
		
		but we can use only two fillRect:
	 
		1. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
		2. BBBBBBBBBBBWWWWWWWWWWBBBBBBBBBBB
	 
		If further optimization of background drawing is needed, consider the 2D reduction.
	 */
	for (c = start; c <= end; c++) {
		if (c < end) {
			currAttr = (currRow + c)->attr;
			currentBackgroundColor = currAttr.f.reverse ? currAttr.f.fgColor : currAttr.f.bgColor;
		}
		
		if (currentBackgroundColor != lastBackgroundColor || c == end) {
			/* Draw Background */
			NSRect rect = NSMakeRect((c - length) * _fontWidth, (gRow - 1 - r) * _fontHeight,
								  _fontWidth * length, _fontHeight);
			[[gConfig colorAtIndex: lastBackgroundColor hilite: NO] set];
			[NSBezierPath fillRect: rect];
			
			/* finish this segment */
			length = 1;
			lastAttr.v = currAttr.v;
			lastBackgroundColor = currentBackgroundColor;
		} else {
			length++;
		}
	}
	
	[self setNeedsDisplayInRect: rowRect];
}

- (void) drawSpecialSymbol: (unichar) ch forRow: (int) r column: (int) c leftAttribute: (attribute) attr1 rightAttribute: (attribute) attr2 {
	int colorIndex1 = attr1.f.reverse ? attr1.f.bgColor : attr1.f.fgColor;
	int colorIndex2 = attr2.f.reverse ? attr2.f.bgColor : attr2.f.fgColor;
	NSPoint origin = NSMakePoint(c * _fontWidth, (gRow - 1 - r) * _fontHeight);

	NSAffineTransform *xform = [NSAffineTransform transform]; 
	[xform translateXBy: origin.x yBy: origin.y];
	[xform concat];
	
	if (colorIndex1 == colorIndex2 && attr1.f.bold == attr2.f.bold) {
		NSColor *color = [gConfig colorAtIndex: colorIndex1 hilite: attr1.f.bold];
		
		if (ch == 0x25FC) { // ◼ BLACK SQUARE
			[color set];
			[NSBezierPath fillRect: gSymbolBlackSquareRect];
		} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
			[color set];
			[NSBezierPath fillRect: gSymbolLowerBlockRect[ch - 0x2581]];
		} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
			[color set];
			[NSBezierPath fillRect: gSymbolLeftBlockRect[ch - 0x2589]];		
		} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
            [color set];
            [gSymbolTrianglePath[ch - 0x25E2] fill];
		} else if (ch == 0x0) {
		}
	} else { // double color
		NSColor *color1 = [gConfig colorAtIndex: colorIndex1 hilite: attr1.f.bold];
		NSColor *color2 = [gConfig colorAtIndex: colorIndex2 hilite: attr2.f.bold];
		if (ch == 0x25FC) { // ◼ BLACK SQUARE
			[color1 set];
			[NSBezierPath fillRect: gSymbolBlackSquareRect1];
			[color2 set];
			[NSBezierPath fillRect: gSymbolBlackSquareRect2];
		} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
			[color1 set];
			[NSBezierPath fillRect: gSymbolLowerBlockRect1[ch - 0x2581]];
			[color2 set];
            [NSBezierPath fillRect: gSymbolLowerBlockRect2[ch - 0x2581]];
		} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
			[color1 set];
			[NSBezierPath fillRect: gSymbolLeftBlockRect1[ch - 0x2589]];
            if (ch <= 0x259B) {
                [color2 set];
                [NSBezierPath fillRect: gSymbolLeftBlockRect2[ch - 0x2589]];
            }
		} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
            [color1 set];
            [gSymbolTrianglePath1[ch - 0x25E2] fill];
            [color2 set];
            [gSymbolTrianglePath2[ch - 0x25E2] fill];
		}
	}
	[xform invert];
	[xform concat];
}


#pragma mark -
#pragma mark Override

- (BOOL) isFlipped {
	return NO;
}

- (BOOL) isOpaque {
	return YES;
}

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem {
    [[tabViewItem identifier] close];
    [super removeTabViewItem: tabViewItem];
}

#pragma mark -
#pragma mark Accessor

- (int)x {
    return _x;
}

- (void)setX:(int)value {
    if (_x != value) {
        _x = value;
    }
}

- (int) y {
    return _y;
}

- (void) setY: (int) value {
    if (_y != value) {
        _y = value;
    }
}

- (BOOL) connected {
	return [[self telnet] connected];
}

- (YLTerminal *) dataSource {
    return (YLTerminal *)[[self telnet] terminal];
}

- (YLTelnet *) telnet {
    return (YLTelnet *)[[self selectedTabViewItem] identifier];
}

#pragma mark - 
#pragma mark NSTextInput Protocol
/* NSTextInput protocol */
// instead of keyDown: aString can be NSString or NSAttributedString
- (void) insertText: (id) aString {
	[_textField setHidden: YES];
	[_markedText release];
	_markedText = nil;	
	
	int i;
	NSMutableData *data = [NSMutableData data];
	for (i = 0; i < [aString length]; i++) {
		unichar ch = [aString characterAtIndex: i];
		unsigned char buf[2];
		if (ch < 0x007F) {
			buf[0] = ch;
			[data appendBytes: buf length: 1];
		} else {
			unichar big5 = U2B[ch];
			buf[0] = big5 >> 8;
			buf[1] = big5 & 0xFF;
			[data appendBytes: buf length: 2];
		}
	}
	[[self telnet] sendMessage: data];
}

- (void) doCommandBySelector:(SEL)aSelector {
	unsigned char ch[10];
	if (strcmp((char *) aSelector, "insertNewline:") == 0) {
		ch[0] = 0x0D;
		[[self telnet] sendBytes: ch length: 1];
	} else if (strcmp((char *) aSelector, "cancelOperation:") == 0) {
	} else if (strcmp((char *) aSelector, "cancel:") == 0) {
	} else if (strcmp((char *) aSelector, "scrollToBeginningOfDocument:") == 0) {
	} else if (strcmp((char *) aSelector, "scrollToEndOfDocument:") == 0) {
	} else if (strcmp((char *) aSelector, "scrollPageUp:") == 0) {
	} else if (strcmp((char *) aSelector, "scrollPageDown:") == 0) {
	} else if (strcmp((char *) aSelector, "insertTab:") == 0) {
        ch[0] = 0x09;
		[[self telnet] sendBytes: ch length: 1];
    }
}

// setMarkedText: cannot take a nil first argument. aString can be NSString or NSAttributedString
- (void) setMarkedText:(id)aString selectedRange:(NSRange)selRange {
    YLTerminal *ds = [self dataSource];
	if ([aString isKindOfClass: [NSString class]])
		aString = [[[NSAttributedString alloc] initWithString: aString] autorelease];

	if ([aString length] == 0) {
		[self unmarkText];
		return;
	}
	
	if (_markedText != aString) {
		[_markedText release];
		_markedText = [aString retain];
	}
	_selectedRange = selRange;
	_markedRange.location = 0;
	_markedRange.length = [aString length];
		
	[_textField setString: aString];
	[_textField setSelectedRange: selRange];
	[_textField setMarkedRange: _markedRange];

	NSPoint o = NSMakePoint(ds->_cursorX * _fontWidth, (gRow - 1 - ds->_cursorY) * _fontHeight + 5.0);
	CGFloat dy;
	if (o.x + [_textField frame].size.width > gColumn * _fontWidth) 
		o.x = gColumn * _fontWidth - [_textField frame].size.width;
	if (o.y + [_textField frame].size.height > gRow * _fontHeight) {
		o.y = (gRow - ds->_cursorY) * _fontHeight - 5.0 - [_textField frame].size.height;
		dy = o.y + [_textField frame].size.height;
	} else {
		dy = o.y;
	}
	[_textField setFrameOrigin: o];
	[_textField setDestination: [_textField convertPoint: NSMakePoint((ds->_cursorX + 0.5) * _fontWidth, dy)
												fromView: self]];
	[_textField setHidden: NO];
}

- (void) unmarkText {
	[_markedText release];
	_markedText = nil;
	[_textField setHidden: YES];
}

- (BOOL) hasMarkedText {
	return (_markedText != nil);
}

- (NSInteger) conversationIdentifier {
	return (NSInteger) self;
}

/* Returns attributed string at the range.  This allows input mangers to query any range in backing-store.  May return nil.
 */
- (NSAttributedString *) attributedSubstringFromRange:(NSRange)theRange {
	if (theRange.location < 0 || theRange.location >= [_markedText length]) return nil;
	if (theRange.location + theRange.length > [_markedText length]) 
		theRange.length = [_markedText length] - theRange.location;
	return [[[NSAttributedString alloc] initWithString: [[_markedText string] substringWithRange: theRange]] autorelease];
}

/* This method returns the range for marked region.  If hasMarkedText == false, it'll return NSNotFound location & 0 length range.
 */
- (NSRange) markedRange {
	return _markedRange;
}

/* This method returns the range for selected region.  Just like markedRange method, its location field contains char index from the text beginning.
 */
- (NSRange) selectedRange {
	return _selectedRange;
}

/* This method returns the first frame of rects for theRange in screen coordindate system.
 */
- (NSRect) firstRectForCharacterRange:(NSRange)theRange {
	NSPoint pointInWindowCoordinates;
	NSRect rectInScreenCoordinates;
	
	pointInWindowCoordinates = [_textField frame].origin;
	//[_textField convertPoint: [_textField frame].origin toView: nil];
	rectInScreenCoordinates.origin = [[_textField window] convertBaseToScreen: pointInWindowCoordinates];
	rectInScreenCoordinates.size = [_textField bounds].size;

	return rectInScreenCoordinates;
}

/* This method returns the index for character that is nearest to thePoint.  thPoint is in screen coordinate system.
 */
- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint {
	return 0;
}

/* This method is the key to attribute extension.  We could add new attributes through this method. NSInputServer examines the return value of this method & constructs appropriate attributed string.
 */
- (NSArray*) validAttributesForMarkedText {
	return [NSArray array];
}

@end
