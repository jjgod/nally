//
//  YLController.h
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLView.h"

@class YLTerminal;

@interface YLController : NSObject {
	IBOutlet id _telnetView;
	IBOutlet id _addressBar;
	IBOutlet NSSegmentedControl *_tab;

	NSMutableArray *_connections;
	int _selectedIndex;
}

- (IBAction)connect:(id )sender;
- (IBAction)openLocation:(id )sender;
- (IBAction) clickTab: (id) sender;

- (NSArray *)connections;
- (unsigned)countOfConnections;
- (id)objectInConnectionsAtIndex:(unsigned)theIndex;
- (void)getConnections:(id *)objsPtr range:(NSRange)range;
- (void)insertObject:(id)obj inConnectionsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromConnectionsAtIndex:(unsigned)theIndex;
- (void)replaceObjectInConnectionsAtIndex:(unsigned)theIndex withObject:(id)obj;

- (int)selectedIndex;
- (void)setSelectedIndex:(int)value;


@end
