//
//  HelloNally.m
//  HelloNally
//
//  Created by Jjgod Jiang on 8/17/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import "HelloNally.h"

@implementation HelloNally

- (id) init
{
	if (self = [super init])
	{
        // note: we can't use - NSLocalizedString(@"BundleDescription", "");
        // because the main bundle is always the app, so we need to target our 
        // own bundle this way ... and since these are localized to this bundle/class
        description = [[NSBundle bundleForClass: [self class]] localizedStringForKey: @"BundleDescription" 
                                                                               value: @"" 
                                                                               table: nil];
        title = [[NSBundle bundleForClass: [self class]] localizedStringForKey: @"BundleTitle" 
                                                                         value: @"" 
                                                                         table: nil];
        NSLog(@"Loading Bundle HelloNally.");
        [self addMenuItemWithTitle: @"Hey" 
                            action: nil 
                     keyEquivalent: @""];        
    }
	
	return self;
}

@end
