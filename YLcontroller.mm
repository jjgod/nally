//
//  YLController.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLController.h"
#import "YLTelnet.h"
#import "YLTerminal.h"

@implementation YLController

- (void) awakeFromNib {
    [_tab setStyleNamed: @"Metal"];
    [_tab setCanCloseOnlyTab: YES];
    
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Sites"];
    for (NSDictionary *d in array) {
        YLSite *s = [[YLSite new] autorelease];
        [s setName: [d objectForKey: @"name"]];
        [s setAddress: [d objectForKey: @"address"]];
        [self insertObject: s inSitesAtIndex: [self countOfSites]];
    }

    NSLog(@"sites: %@",_sites);
}

#pragma mark -
#pragma mark Actions

- (IBAction) connect: (id) sender {
	[sender abortEditing];
	[[_telnetView window] makeFirstResponder: _telnetView];
	
	id telnet = [YLTelnet new];
	id terminal = [YLTerminal new];
	[telnet setTerminal: terminal];
    [telnet setConnectionName: [sender stringValue]];
	[terminal setDelegate: _telnetView];
    
    NSTabViewItem *tabItem = [[NSTabViewItem alloc] initWithIdentifier: telnet];
    [tabItem setLabel: [sender stringValue]];
    [_telnetView addTabViewItem: tabItem];
	
	[telnet connectToAddress: [sender stringValue] port: 23];
    [_telnetView selectTabViewItem: tabItem];
    [tabItem release];
    [terminal release];
    [telnet release];
}

- (IBAction) openLocation: (id) sender {
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
}

- (IBAction) recoonect: (id) sender {
    [[_telnetView telnet] reconnect];
}

- (IBAction) selectNextTab: (id) sender {
    if ([_telnetView indexOfTabViewItem: [_telnetView selectedTabViewItem]] == [_telnetView numberOfTabViewItems] - 1)
        [_telnetView selectFirstTabViewItem: self];
    else
        [_telnetView selectNextTabViewItem: self];
}

- (IBAction) selectPrevTab: (id) sender {
    if ([_telnetView indexOfTabViewItem: [_telnetView selectedTabViewItem]] == 0)
        [_telnetView selectLastTabViewItem: self];
    else
        [_telnetView selectPreviousTabViewItem: self];
}

- (IBAction) closeTab: (id) sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    
    NSTabViewItem *tabItem = [_telnetView selectedTabViewItem];
    
    [_telnetView removeTabViewItem: tabItem];
}

- (IBAction) editSites: (id) sender {
    [NSApp beginSheet: _sitesWindow
       modalForWindow: _mainWindow
        modalDelegate: nil
       didEndSelector: NULL
          contextInfo: nil];
}

- (IBAction) openSites: (id) sender {
    NSArray *a = [_sitesController selectedObjects];
    [self closeSites: sender];
    
    if ([a count] == 1) {
        YLSite *s = [a objectAtIndex: 0];
        id telnet = [YLTelnet new];
        id terminal = [YLTerminal new];
        [telnet setTerminal: terminal];
        [telnet setConnectionName: [s name]];
        [terminal setDelegate: _telnetView];
        
        NSTabViewItem *tabItem = [[NSTabViewItem alloc] initWithIdentifier: telnet];
        [tabItem setLabel: [s name]];
        [_telnetView addTabViewItem: tabItem];
        
        [telnet connectToAddress: [s address] port: 23];
        [_telnetView selectTabViewItem: tabItem];
        [tabItem release];
        [terminal release];
    }
}

- (IBAction) closeSites: (id) sender {
    [NSApp endSheet: _sitesWindow];
    [_sitesWindow orderOut: self];
    NSMutableArray *a = [NSMutableArray array];
    for (YLSite *s in _sites) 
        [a addObject: [NSDictionary dictionaryWithObjectsAndKeys: [s name], @"name", [s address], @"address", nil]];
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"Sites"];
    
}


#pragma mark -
#pragma mark Accessor

- (NSArray *)sites {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [[_sites retain] autorelease];
}

- (unsigned)countOfSites {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [_sites count];
}

- (id)objectInSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    return [_sites objectAtIndex:theIndex];
}

- (void)getSites:(id *)objsPtr range:(NSRange)range {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromSitesAtIndex:(unsigned)theIndex {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInSitesAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!_sites) {
        _sites = [[NSMutableArray alloc] init];
    }
    [_sites replaceObjectAtIndex:theIndex withObject:obj];
}


#pragma mark -
#pragma mark Window Delegation

- (BOOL) windowShouldClose: (id) window {
    NSLog(@"SHOULD");
    return NO;
}

- (BOOL) windowWillClose: (id) window {
//    [NSApp terminate: self];
    NSLog(@"WILL");
    return NO;
}

- (void) windowDidBecomeKey: (NSNotification *) notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask | NSShiftKeyMask];
    [_closeTabMenuItem setKeyEquivalent: @"w"];
}

- (void) windowDidResignKey: (NSNotification *) notification {
    [_closeWindowMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
    [_closeTabMenuItem setKeyEquivalent: @""];
}

#pragma mark -
#pragma mark Tab Delegation

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (void)tabView:(NSTabView *)tabView willCloseTabViewItem:(NSTabViewItem *)tabViewItem {

}

- (void)tabView:(NSTabView *)tabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {

}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [_telnetView update];
    [_addressBar setStringValue: [[tabViewItem identifier] connectionName]];
    [_telnetView setNeedsDisplay: YES];
    [_mainWindow makeFirstResponder: _telnetView];
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [[[tabViewItem identifier] terminal] setAllDirty];
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl {
	return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
	return YES;
}

- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask {
    return nil;
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView {
    
}
@end
