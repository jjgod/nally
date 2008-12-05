//
//  ImagePreviewer.m
//  ImagePreviewer
//
//  Created by Jjgod Jiang on 8/18/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import "ImagePreviewer.h"

@implementation ImagePreviewer

- (id) init
{
	if (self = [super init])
	{
        // note: we can't use - NSLocalizedString(@"BundleDescription", "");
        // because the main bundle is always the app, so we need to target our 
        // own bundle this way ... and since these are localized to this bundle/class
        description = [self localizedStringForKey: @"BundleDescription"];
        title = [self localizedStringForKey: @"BundleTitle"];
        enabled = YES;

        NSLog(@"Loading Bundle ImagePreviewer.");
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [self localizedStringForKey: @"EnableImagePreview"]
                                                      action: @selector(flipEnabled:)
                                               keyEquivalent: @""];
        [item setState: NSOnState];
        [self addMenuItem: item];
        [item release];
    }
	
	return self;
}

- (IBAction) flipEnabled: (id) sender
{
    enabled = !enabled;
    [(NSMenuItem *) sender setState: enabled ? NSOnState : NSOffState];
}

@end
