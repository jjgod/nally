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
#import "YLLGlobalConfig.h"

@implementation YLController

- (void) updateSitesMenu {
    int total = [[_sitesMenu submenu] numberOfItems] ;
    int i;
    for (i = 3; i < total; i++) {
        [[_sitesMenu submenu] removeItemAtIndex: 3];
    }
    
    for (YLSite *s in _sites) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [s name] action: @selector(openSiteMenu:) keyEquivalent: @""];
        [menuItem setRepresentedObject: s];
        [[_sitesMenu submenu] addItem: menuItem];
        [menuItem release];        
    }
}

- (void) awakeFromNib {
    [_tab setStyleNamed: @"Metal"];
    [_tab setCanCloseOnlyTab: YES];
    
    [[YLLGlobalConfig sharedInstance] setShowHiddenText: [[NSUserDefaults standardUserDefaults] boolForKey: @"ShowHiddenText"]];
    
    NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Sites"];
    for (NSDictionary *d in array) {
        YLSite *s = [[YLSite new] autorelease];
        [s setName: [d objectForKey: @"name"]];
        [s setAddress: [d objectForKey: @"address"]];
        [self insertObject: s inSitesAtIndex: [self countOfSites]];
    }

    [self updateSitesMenu];
}

- (void) saveSites {
    NSMutableArray *a = [NSMutableArray array];
    for (YLSite *s in _sites) 
        [a addObject: [NSDictionary dictionaryWithObjectsAndKeys: [s name], @"name", [s address], @"address", nil]];
    [[NSUserDefaults standardUserDefaults] setObject: a forKey: @"Sites"];
    [self updateSitesMenu];
}

- (void) newConnectionToAddress: (NSString *) addr name: (NSString *) name {
    id telnet = [YLTelnet new];
	id terminal = [YLTerminal new];
	[telnet setTerminal: terminal];
    [telnet setConnectionName: name];
    [telnet setConnectionAddress: addr];
	[terminal setDelegate: _telnetView];
    
    NSTabViewItem *tabItem = [[NSTabViewItem alloc] initWithIdentifier: telnet];
    [tabItem setLabel: name];
    [_telnetView addTabViewItem: tabItem];
	
	[telnet connectToAddress: addr port: 23];
    [_telnetView selectTabViewItem: tabItem];
    [tabItem release];
    [terminal release];
    [telnet release];
}

#pragma mark -
#pragma mark Actions

- (IBAction) connect: (id) sender {
	[sender abortEditing];
	[[_telnetView window] makeFirstResponder: _telnetView];

	[self newConnectionToAddress: [sender stringValue] name: [sender stringValue]];
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
        [self newConnectionToAddress: [s address] name: [s name]];
    }
}

- (IBAction) openSiteMenu: (id) sender {
    YLSite *s = [sender representedObject];
    [self newConnectionToAddress: [s address] name: [s name]];
}

- (IBAction) closeSites: (id) sender {
    [_sitesWindow endEditingFor: nil];
    [NSApp endSheet: _sitesWindow];
    [_sitesWindow orderOut: self];
    [self saveSites];
}

- (IBAction) addSites: (id) sender {
    if ([_telnetView numberOfTabViewItems] == 0) return;
    NSString *address = [[_telnetView telnet] connectionAddress];
    
    for (YLSite *s in _sites) 
        if ([[s address] isEqualToString: address]) 
            return;
    
    YLSite *s = [[YLSite new] autorelease];
    [s setName: address];
    [s setAddress: address];
    [_sitesController addObject: s];
    [_sitesController setSelectedObjects: [NSArray arrayWithObject: s]];
    [self performSelector: @selector(editSites:) withObject: sender afterDelay: 0.1];
    [_sitesTableView editColumn: 0 row: [_sitesTableView selectedRow] withEvent: nil select: YES];
}

- (IBAction) showHiddenText: (id) sender {
    [[YLLGlobalConfig sharedInstance] setShowHiddenText: ([sender state] == NSOnState)];
    [_telnetView refreshHiddenRegion];
    [_telnetView update];
    [_telnetView setNeedsDisplay: YES];
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
    NSLog(@"%d", [[tabViewItem identifier] retainCount]);
//    [[tabViewItem identifier] release];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [_telnetView update];
    [_addressBar setStringValue: [[tabViewItem identifier] connectionAddress]];
    [_telnetView setNeedsDisplay: YES];
    [_mainWindow makeFirstResponder: _telnetView];
    if ([[tabViewItem identifier] connected]) {
        [[tabViewItem identifier] setValue: [NSImage imageNamed: @"connect.pdf"] forKey: @"icon"];
    }
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
