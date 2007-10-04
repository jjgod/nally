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
}

- (IBAction) connect:(id )sender {
	[sender abortEditing];
	[[_telnetView window] makeFirstResponder: _telnetView];
	
	id telnet = [YLTelnet new];
	id terminal = [YLTerminal new];
	[telnet setTerminal: terminal];
	[telnet setServerAddress: [sender stringValue]];
	[terminal setDelegate: _telnetView];
	[_telnetView setDataSource: terminal];
	[_telnetView setTelnet: telnet];

	_selectedIndex = [self countOfConnections];
	if (_selectedIndex < 0) _selectedIndex = 0;
	[self insertObject: telnet inConnectionsAtIndex: _selectedIndex];

	[_tab setSegmentCount: [self countOfConnections]];
	
	NSUInteger i, count = [self countOfConnections];
	for (i = 0; i < count; i++) {
		YLTelnet * obj = [self objectInConnectionsAtIndex: i];
		[_tab setLabel: [obj serverAddress] forSegment: i];
		NSLog(@"%d - %@", i, [obj serverAddress]);
		[_tab setWidth: 120.0 forSegment: i];
	}
	[_tab setSelectedSegment: _selectedIndex];
	NSSize size = [_tab frame].size;
	size.width = 120.0 * [self countOfConnections] + 10;
	[_tab setFrameSize: size];
	
	[telnet connectToAddress: [sender stringValue] port: 23];
}

- (IBAction) openLocation:(id )sender {
	[_telnetView resignFirstResponder];
	[_addressBar becomeFirstResponder];
}

- (IBAction) clickTab: (id) sender {
	_selectedIndex = [_tab selectedSegment];
	id telnet = [self objectInConnectionsAtIndex: _selectedIndex];
	[_addressBar setStringValue: [telnet serverAddress]];
	[_telnetView setTelnet: telnet];
	[_telnetView setDataSource: [telnet terminal]];
	[[telnet terminal] setAllDirty];
	[_telnetView update];
}

- (NSArray *)connections {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    return [[_connections retain] autorelease];
}


- (unsigned)countOfConnections {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    return [_connections count];
}

- (id)objectInConnectionsAtIndex:(unsigned)theIndex {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    return [_connections objectAtIndex:theIndex];
}

- (void)getConnections:(id *)objsPtr range:(NSRange)range {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    [_connections getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inConnectionsAtIndex:(unsigned)theIndex {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    [_connections insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromConnectionsAtIndex:(unsigned)theIndex {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    [_connections removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInConnectionsAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!_connections) {
        _connections = [[NSMutableArray alloc] init];
    }
    [_connections replaceObjectAtIndex:theIndex withObject:obj];
}
	 
- (int)selectedIndex {
    return _selectedIndex;
}

- (void)setSelectedIndex:(int)value {
    if (_selectedIndex != value) {
        _selectedIndex = value;
    }
}

@end
