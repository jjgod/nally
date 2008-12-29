//
//  YLImageView.m
//  MacBlueTelnet
//
//  Created by Jjgod Jiang on 3/27/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import "YLImageView.h"

@interface NSBezierPath (RoundRect)
- (void) appendBezierPathWithRoundedRect: (NSRect)rect cornerRadius: (float)radius;
+ (NSBezierPath *) bezierPathWithRoundedRect: (NSRect)rect cornerRadius: (float)radius;
@end


@implementation NSBezierPath (RoundRect)
- (void) appendBezierPathWithRoundedRect: (NSRect)rect cornerRadius: (float)radius
{
    if (!NSIsEmptyRect(rect))
    {
        if (radius > 0.0) {
            // Clamp radius to be no larger than half the rect's width or height.
            float clampedRadius = MIN(radius, 0.5 * MIN(rect.size.width,  
                                                        rect.size.height));
            
            NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
            NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
            NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
            
            [self moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
            [self appendBezierPathWithArcFromPoint:topLeft      
                                           toPoint:rect.origin radius:clampedRadius];
            [self appendBezierPathWithArcFromPoint:rect.origin  
                                           toPoint:bottomRight radius:clampedRadius];
            [self appendBezierPathWithArcFromPoint:bottomRight  
                                           toPoint:topRight    radius:clampedRadius];
            [self appendBezierPathWithArcFromPoint:topRight    
                                           toPoint:topLeft    radius:clampedRadius];
            [self closePath];
        } else {
            // When radius == 0.0, this degenerates to the simple case of a plain rectangle.
            [self appendBezierPathWithRect:rect];
        }
    }
}

+ (NSBezierPath *) bezierPathWithRoundedRect: (NSRect)rect cornerRadius: (float)radius 
{
    NSBezierPath *result = [NSBezierPath bezierPath];
    [result appendBezierPathWithRoundedRect:rect cornerRadius:radius];
    return result;
}

@end

@implementation YLImageView

- (id) initWithFrame: (NSRect)frame previewer: (YLImagePreviewer *)thePreviewer
{
    if ([super initWithFrame: frame])
    {
        tipsState = kShowTipsGray;
        tipsRect = NSMakeRect(10, 10, 65, 30);
        previewer = thePreviewer;
        [[self window] setAcceptsMouseMovedEvents: YES];
        [self addTrackingRect: [self bounds] 
                        owner: self 
                     userData: nil
                 assumeInside: NO];
    }
    
    return self;
}

- (void) drawRect: (NSRect)rect
{
    [super drawRect: rect];

    if (tipsState != kShowTipsNone && 
        [self bounds].size.width > tipsRect.origin.x + tipsRect.size.width &&
        [self bounds].size.height > tipsRect.origin.y + tipsRect.size.height)
    {
        NSColor *color = [NSColor colorWithCalibratedRed: 0 
                                                   green: 0 
                                                    blue: 0 
                                                   alpha: 0.5];
        [color set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: tipsRect
                                                        cornerRadius: 8.0];
        [path fill];
        
        NSColor *tipsColor = (tipsState == kShowTipsWhite ? [NSColor whiteColor] : [NSColor colorWithCalibratedRed: 0.8 
                                                                                                             green: 0.8 
                                                                                                              blue: 0.8 
                                                                                                             alpha: 1.0]);

        NSFont *font = [NSFont systemFontOfSize: 16.0];
        NSString *tips = @"Save...";
        NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys: 
                  tipsColor, NSForegroundColorAttributeName, 
                  font, NSFontAttributeName, nil];
        
        [tips drawAtPoint: NSMakePoint(20, 15)
           withAttributes: attrib];
    }
}

- (void) mouseDown: (NSEvent *)event
{
    NSPoint location = [event locationInWindow];
    NSPoint point = [self convertPoint: location fromView: nil];
    
    if ([self mouse: point inRect: tipsRect])
    {        
        tipsState = kShowTipsWhite;
        [self setNeedsDisplay: YES];
    }
}

- (void) mouseUp: (NSEvent *)event
{
    NSPoint location = [event locationInWindow];
    NSPoint point = [self convertPoint: location fromView: nil];
    
    if ([self mouse: point inRect: tipsRect])
    {
        NSSavePanel *panel = [NSSavePanel savePanel];
        
        if ([panel runModalForDirectory: nil 
                                   file: [previewer filename]] == NSFileHandlingPanelOKButton)
        {
            /* BOOL ret = */ [[previewer receivedData] writeToFile: [panel filename] 
                                                  atomically: YES];
            // NSLog(@"save as %@: %s", [panel filename], ret == YES ? "done" : "failed");
        }
    }
    
    tipsState = kShowTipsGray;
    [self setNeedsDisplay: YES];
}

- (void) mouseEntered: (NSEvent *)event
{
    tipsState = kShowTipsGray;
    [self setNeedsDisplay: YES];
}

- (void)mouseExited: (NSEvent *)event
{
    tipsState = kShowTipsNone;
    [self setNeedsDisplay: YES];
}

- (void) setPreviewer: (YLImagePreviewer *)thePreviewer
{
    previewer = thePreviewer;
}

- (YLImagePreviewer *) previewer
{
    return previewer;
}

@end
