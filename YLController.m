//
//  YLController.m
//  MacBlueTelnet
//
//  Created by Yung-Luen Lan on 9/11/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLController.h"
#import "YLTelnet.h"

@class YLTerminal;

@implementation YLController

- (void) awakeFromNib {
//	unsigned char data[] = {0xa4, 0xa4, 0xa4, 0xe5, 0x0A, 0x0D, 0x1B, '[', '3','3','m','P', 'T', 'T'};
	YLTelnet *telnet = [YLTelnet new];
	_terminal = [YLTerminal new];
	[telnet setTerminal: _terminal];
	[_terminal setDelegate: _telnetView];
	[_telnetView setDataSource: _terminal];
	[_telnetView setTelnet: telnet];
	
	[telnet connectToAddress: @"ptt2.cc" port: 23];

}

@end
