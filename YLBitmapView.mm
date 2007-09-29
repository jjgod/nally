//
//  YLView.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 2006/6/9.
//  Copyright 2006 yllan.org. All rights reserved.
//

#import "YLBitmapView.h"
#import "YLTerminal.h"
#import "encoding.h"
#import "YLTelnet.h"
#import "YLLGLobalConfig.h"

@implementation YLBitmapView

static YLLGlobalConfig *gConfig;
static int gRow;
static int gColumn;
static int gTotalPixels;
static int gRowPixels;
static int gLinePixels;

- (id)initWithFrame:(NSRect)frame {
	if (!gConfig) gConfig = [YLLGlobalConfig sharedInstance];
	gColumn = [gConfig column];
	gRow = [gConfig row];
	
	frame.size = NSMakeSize(gColumn * [gConfig cellWidth], gRow * [gConfig cellHeight]);
    self = [super initWithFrame: frame];
    if (self) {
		_bgColor = [[NSColor colorWithCalibratedRed: 0.0 green: 0.0470588 blue: 0.2431372 alpha: 1.0] retain];
		_fgColor = [[NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0] retain];

		_fontWidth = [gConfig cellWidth];
		_fontHeight = [gConfig cellHeight];
		
		gLinePixels = gColumn * _fontWidth;
		gRowPixels = gLinePixels * _fontHeight;
		gTotalPixels = gRowPixels * gRow;
				
		_imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
														  pixelsWide: gLinePixels
														  pixelsHigh: gRow * _fontHeight 
													   bitsPerSample: 8
													 samplesPerPixel: 3
															hasAlpha: NO
															isPlanar: NO
													  colorSpaceName: NSCalibratedRGBColorSpace
														 bytesPerRow: gLinePixels * 4
														bitsPerPixel: 32];
		_mem = (unsigned int *) [_imgRep bitmapData];
    }
    return self;
}

- (void) dealloc {
	free(_mem);
	[super dealloc];
}

#pragma mark -
#pragma mark Event Handling
- (void) mouseDown: (NSEvent *) e {
	NSLog(@"%X %d %d", [_dataSource charAtRow: 1 column: 78], [_dataSource isDoubleByteAtRow: 1 column: 78], [_dataSource isDoubleByteAtRow: 1 column: 79]);
}

- (void) keyDown: (NSEvent *) e {
	unichar c = [[e charactersIgnoringModifiers] characterAtIndex: 0];
	unsigned char arrow[3] = {0x1B, 0x4F, 0x00};
	
	if (c == NSUpArrowFunctionKey) arrow[2] = 'A';
	if (c == NSDownArrowFunctionKey) arrow[2] = 'B';
	if (c == NSRightArrowFunctionKey) arrow[2] = 'C';
	if (c == NSLeftArrowFunctionKey) arrow[2] = 'D';
	if (c == NSUpArrowFunctionKey || c == NSDownArrowFunctionKey || c == NSRightArrowFunctionKey || c == NSLeftArrowFunctionKey) {
		[_telnet sendBytes: arrow length: 3];
		return;
	}
	
	unsigned char ch = (unsigned char) c;
	[_telnet sendBytes: &ch length: 1];		
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)rect {
	[_imgRep drawAtPoint: NSMakePoint(0, 0)];
}

- (void) update {
	int x, y;
	for (y = 0; y < gRow; y++) {
		[_dataSource updateDoubleByteStateForRow: y];
		for (x = 0; x < gColumn; x++) {
			if ([_dataSource isDirtyAtRow: y column: x]) {
				int startx = x;
				for (; x < gColumn && [_dataSource isDirtyAtRow:y column:x]; x++) ;
				[self updateRow: y from: startx to: x];
				for(x--; x >= startx; x--) 
					[_dataSource setDirty: NO atRow: y column: x];
			}
		}
	}
	[self setNeedsDisplay: YES];
}

- (void) updateRow: (int) r from: (int) start to: (int) end {
	int c;
	cell *currRow = [_dataSource cellsOfRow: r];
	NSRect rowRect = NSMakeRect(start * _fontWidth, r * _fontHeight, (end - start) * _fontWidth, _fontHeight);

	attribute currAttr, lastAttr = (currRow + start)->attr;
	int length = 0;

	for (c = start; c <= end; c++) {
		if (c < end)
			currAttr = (currRow + c)->attr;
		if (currAttr.v != lastAttr.v || c == end) {
			/* Draw Background */
			NSRect rect = NSMakeRect((c - length) * _fontWidth, r * _fontHeight,
								  _fontWidth * length, _fontHeight);
			int idx = lastAttr.f.reverse ? lastAttr.f.fgColor : lastAttr.f.bgColor;
			unsigned int color = gConfig->_bitmapColorTable[0][idx];
			int i, j;
			int base = gRowPixels * r + (c - length) * _fontWidth;
			for (j = 0; j < _fontHeight; j++) {
				for (i = 0; i < length * _fontWidth; i++) {
					_mem[base + i] = color;
				}
				base += gLinePixels;
			}
			
			/* Draw Foreground */
			int x;
			for (x = c - length; x < c; x++) {
				int db = (currRow + x)->attr.f.doubleByte;
				
				int colorIndex = lastAttr.f.reverse?lastAttr.f.bgColor:lastAttr.f.fgColor;
				
				/* Draw Underline */
				if (lastAttr.f.underline) {
					color = gConfig->_bitmapColorTable[lastAttr.f.bold][colorIndex];
					base = gRowPixels * (r+1) + x * _fontWidth - gLinePixels;
					for (i = 0; i < _fontWidth; i++)
						_mem[base + i] = color;
				}
				
				/* Draw Character */
				if (db == 1) continue;
				
				unichar ch;
				
				if (db == 0) { // English
					ch = (currRow + x)->byte;
//					ch = [_dataSource charAtRow: r column: x];
					[self drawChar: ch atPoint: NSMakePoint(x * _fontWidth, r * _fontHeight) 
					  withAttribute: lastAttr];
				} else if (db == 2) { // Chinese
					if (x == start) {
						rowRect.origin.x -= _fontWidth;
						rowRect.size.width += _fontWidth;							
					}

					ch = B2U[(((currRow + x - 1)->byte) << 8) + (currRow + x)->byte - 0x8000];
//					ch = [_dataSource charAtRow: r column: x - 1];

					[self drawChar: ch atPoint: NSMakePoint((x-1) * _fontWidth, r * _fontHeight) 
					   withAttribute: lastAttr];
//					
//					if (x == c - length) { // double color
//						attribute prevAttr = [_dataSource attrAtRow: r column: x - 1];
//						
//						[gLeftImage lockFocus];
//						int bgColorIndex = prevAttr.f.reverse ? prevAttr.f.fgColor : prevAttr.f.bgColor;
//						[[gConfig colorAtIndex: bgColorIndex hilite: NO] set];
//						[NSBezierPath fillRect: NSMakeRect(0, 0, _fontWidth, _fontHeight)];
//						[self drawChar: ch atPoint: NSMakePoint(0, 0)
//						   withAttribute: prevAttr];
//						[gLeftImage unlockFocus];
//						[gLeftImage compositeToPoint: NSMakePoint((x-1) * _fontWidth, (r+1) * _fontHeight) operation: NSCompositeCopy];
//					}
				}
			}
			
			/* finish this segment */
			length = 1;
			lastAttr.v = currAttr.v;
		} else {
			length++;
		}
	}

}

- (void) drawChar: (unichar) ch atPoint: (NSPoint) origin withAttribute: (attribute) attr  {
	int colorIndex = attr.f.reverse ? attr.f.bgColor : attr.f.fgColor;
	unsigned int color = gConfig->_bitmapColorTable[attr.f.bold][colorIndex];
	int base, i, j;
	base = origin.y * gLinePixels + origin.x;
	
	if (ch <= 0x0020 || ch == 0x0000) {
		return;
	} else if (ch == 0x25FC) { // ◼ BLACK SQUARE
		for (j = 0; j < _fontHeight; j++) {
			for (i = 0; i < _fontWidth * 2; i++) {
				_mem[base + i] = color;
			}
			base += gLinePixels;
		}
	} else if (ch >= 0x2581 && ch <= 0x2588) { // BLOCK ▁▂▃▄▅▆▇█
		base = base + gRowPixels - gLinePixels;
		for (j = 0; j < _fontHeight * (ch - 0x2580) / 8; j++) {
			for (i = 0; i < _fontWidth * 2; i++) {
				_mem[base + i] = color;
			}
			base -= gLinePixels;
		}	
	} else if (ch >= 0x2589 && ch <= 0x258F) { // BLOCK ▉▊▋▌▍▎▏
		int w = _fontWidth * (0x2590 - ch) / 4;
		for (j = 0; j < _fontHeight; j++) {
			for (i = 0; i < w; i++) {
				_mem[base + i] = color;
			}
			base += gLinePixels;
		}
	} else if (ch >= 0x25E2 && ch <= 0x25E5) { // TRIANGLE ◢◣◤◥
		
	} else if (ch == 0x0) {
		
	} else if (ch > 0x0080) {
		origin.y -= 2;
//		NSRect r = NSMakeRect(origin.x + 0.5, origin.y + 2.5, _fontWidth * 2 - 1, _fontHeight - 1);
//		[[NSColor whiteColor] set];
//		[NSBezierPath strokeRect: r];
//		NSString *str = [NSString stringWithCharacters: &ch length: 1];
//		[str drawAtPoint: origin withAttributes: [gConfig cFontAttributeForColorIndex: colorIndex hilite: attr.f.bold]];
	} else {
//		NSRect r = NSMakeRect(origin.x + 0.5, origin.y + 0.5, _fontWidth - 1, _fontHeight - 1);
//		[[NSColor yellowColor] set];
//		[NSBezierPath strokeRect: r];
//		NSString *str = [NSString stringWithCharacters: &ch length: 1];
//		[str drawAtPoint: origin withAttributes: [gConfig eFontAttributeForColorIndex: colorIndex hilite: attr.f.bold]];
	}
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

#pragma mark -
#pragma mark Accessor

- (id)dataSource {
    return [[_dataSource retain] autorelease];
}

- (void)setDataSource:(id)value {
    if (_dataSource != value) {
        [_dataSource release];
        _dataSource = [value retain];
    }
}

- (YLTelnet *)telnet {
	
    return [[_telnet retain] autorelease];
}

- (void)setTelnet:(YLTelnet *)value {
    if (_telnet != value) {
        [_telnet release];
        _telnet = [value retain];
    }
}

@end
