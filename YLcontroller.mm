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
}

- (IBAction) connect:(id )sender {
	[sender abortEditing];
	[[_telnetView window] makeFirstResponder: _telnetView];
	
	id telnet = [YLTelnet new];
	id terminal = [YLTerminal new];
	[telnet setTerminal: terminal];
	[telnet setServerAddress: [sender stringValue]];
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

- (IBAction) openLocation:(id )sender {
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
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
    [_telnetView setNeedsDisplay: YES];
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
