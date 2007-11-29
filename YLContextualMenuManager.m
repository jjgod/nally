//
//  YLContextualMenuManager.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/28/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLContextualMenuManager.h"

static YLContextualMenuManager *gSharedInstance;

@implementation YLContextualMenuManager

+ (YLContextualMenuManager *) sharedInstance {
    return gSharedInstance ?: [[[YLContextualMenuManager alloc] init] autorelease];
}

- (id) init {
    if (gSharedInstance) {
        [self release];
    } else if (self = gSharedInstance = [[super init] retain]) {
        // ...
    }
    return gSharedInstance;
}

- (NSArray *) availableMenuItemForSelectionString: (NSString *) s {
    NSMutableArray *a = [NSMutableArray array];
    NSMenuItem *item;
    NSString *shortURL = [self extractShortURL: s];
    
    if ([shortURL length]) {
        item = [[[NSMenuItem alloc] initWithTitle: [@"http://0rz.tw/" stringByAppendingString: shortURL]
                                                       action: @selector(openURL:)
                                                keyEquivalent: @""] autorelease];
        [item setTarget: self];
        [a addObject: item];
    
        item = [[[NSMenuItem alloc] initWithTitle: [@"http://tinyurl.com/" stringByAppendingString: shortURL]
                                           action: @selector(openURL:)
                                    keyEquivalent: @""] autorelease];
        [item setTarget: self];
        [a addObject: item];
    }
    
    if ([s length] > 0) {
        item = [[[NSMenuItem alloc] initWithTitle: @"Google"
                                           action: @selector(google:)
                                    keyEquivalent: @""] autorelease];
        [item setTarget: self];
        [item setRepresentedObject: s];
        [a addObject: item];
        
        item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Lookup in Dictionary", @"Menu")
                                           action: @selector(lookupDictionary:)
                                    keyEquivalent: @""] autorelease];
        [item setTarget: self];
        [item setRepresentedObject: s];
        [a addObject: item];
    }
    return a;
}

- (NSString *) extractShortURL: (NSString *) s {
    NSMutableString *result = [NSMutableString string];
    
    int i = 0;
    for (i = 0; i < [s length]; i++) {
        unichar c = [s characterAtIndex: i];
        if (('0' <= c && c <= '9') ||
            ('a' <= c && c <= 'z') ||
            ('A' <= c && c <= 'Z'))
            [result appendString: [NSString stringWithCharacters: &c length: 1]];
    }
    return result;
}

- (IBAction) openURL: (id) sender {
    NSString *u = [sender title];
    if (![u hasPrefix: @"http://"])
        u = [@"http://" stringByAppendingString: u];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: u]];
}

- (IBAction) google: (id) sender {
    NSString *u = [sender representedObject];
    u = [@"http://www.google.com/search?q=" stringByAppendingString: [u stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: u]];
}

- (IBAction) lookupDictionary: (id) sender {
    NSString *u = [sender representedObject];
    NSPasteboard *spb = [NSPasteboard pasteboardWithUniqueName];
    [spb declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: self];
    [spb setString: u forType: NSStringPboardType];
    NSPerformService(@"Look Up in Dictionary", spb);
    
}

@end
