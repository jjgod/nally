//
//  YLConnection.mm
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 12/7/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLConnection.h"


@implementation YLConnection

+ (YLConnection *) connectionWithAddress: (NSString *) addr {
    Class c; 
    if ([addr hasPrefix: @"ssh://"])
        c = NSClassFromString(@"YLSSH");
    else
        c = NSClassFromString(@"YLTelnet");
//    NSLog(@"CONNECTION wih addr: %@ %@", addr, c);
    return (YLConnection *)[[[c alloc] init] autorelease];
}

- (void) dealloc {
    [_lastTouchDate release];
    [_icon release];
    [_connectionName release];
    [_connectionAddress release];
    [_terminal release];
    [super dealloc];
}

- (YLTerminal *) terminal {
	return _terminal;
}

- (void) setTerminal: (YLTerminal *) term {
	if (term != _terminal) {
		[_terminal release];
		_terminal = [term retain];
        [_terminal setConnection: self];
	}
}

- (BOOL)connected {
    return _connected;
}

- (void)setConnected:(BOOL)value {
    _connected = value;
    if (_connected) 
        [self setIcon: [NSImage imageNamed: @"connect.pdf"]];
    else {
        [[self terminal] setHasMessage: NO];
        [self setIcon: [NSImage imageNamed: @"offline.pdf"]];
    }
}

- (NSString *)connectionName {
    return _connectionName;
}

- (void)setConnectionName:(NSString *)value {
    if (_connectionName != value) {
        [_connectionName release];
        _connectionName = [value retain];
    }
}

- (NSImage *)icon {
    return _icon;
}

- (void)setIcon:(NSImage *)value {
    if (_icon != value) {
        [_icon release];
        _icon = [value retain];
    }
}

- (NSString *)connectionAddress {
    return _connectionAddress;
}

- (void)setConnectionAddress:(NSString *)value {
    if (_connectionAddress != value) {
        [_connectionAddress release];
        _connectionAddress = [value retain];
    }
}

- (BOOL)isProcessing {
    return _processing;
}

- (void)setIsProcessing:(BOOL)value {
    _processing = value;
}

- (NSDate *) lastTouchDate {
    return _lastTouchDate;
}

/* Empty */
- (void) close {}
- (void) reconnect {}

- (BOOL) connectToAddress: (NSString *) addr { return YES; }
- (BOOL) connectToAddress: (NSString *) addr port: (unsigned int) port { return YES;}

- (void) receiveBytes: (unsigned char *) bytes length: (NSUInteger) length { }
- (void) sendBytes: (unsigned char *) msg length: (NSInteger) length { }
- (void) sendMessage: (NSData *) msg { }

@end
