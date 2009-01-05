//
//  YLImageView.m
//  MacBlueTelnet
//
//  Created by Jjgod Jiang on 3/27/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import "YLImageView.h"

enum {
    kFloatRectWidth  = 100,
    kFloatRectHeight = 60,
};

@implementation YLImageView

- (id) initWithFrame: (NSRect)frame previewer: (YLImagePreviewer *)thePreviewer
{
    if ([super initWithFrame: frame])
    {
        tipsState = kShowTipsGray;
        tipsRect = NSMakeRect((frame.size.width - kFloatRectWidth) / 2, 10, kFloatRectWidth, kFloatRectHeight);
        
        previewer = thePreviewer;
        [self addTrackingRect: frame
                        owner: self 
                     userData: nil
                 assumeInside: NO];
        
        indicator = [[YLFloatingView alloc] initWithFrame: tipsRect];
        [indicator setWantsLayer: YES];
        [indicator setAlphaValue: 0.0];
        [self addSubview: indicator];
    }
    
    return self;
}

- (void) dealloc
{
    [indicator release];
    [super dealloc];
}

- (void) mouseMoved: (NSEvent *)event
{
    [[indicator animator] setAlphaValue: 0.8];
    [[self window] setAcceptsMouseMovedEvents: NO];
}

- (void) mouseEntered: (NSEvent *)event
{
    [[indicator animator] setAlphaValue: 0.8];
}

- (void) mouseExited: (NSEvent *)event
{
    [[indicator animator] setAlphaValue: 0.0];
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
