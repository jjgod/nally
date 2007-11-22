//
//  YLSite.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "YLSite.h"


@implementation YLSite

- (id) init {
    if ([super init]) {
        [self setName: @"Site Name"];
        [self setAddress: @"(your.site.org)"];
    }
    return self;
}

- (NSString *)name {
    return [[_name retain] autorelease];
}

- (void)setName:(NSString *)value {
    if (_name != value) {
        [_name release];
        _name = [value copy];
    }
}

- (NSString *)address {
    return [[_address retain] autorelease];
}

- (void)setAddress:(NSString *)value {
    if (_address != value) {
        [_address release];
        _address = [value copy];
    }
}

- (NSString *) description {
    return [NSString stringWithFormat: @"%@:%@", [self name], [self address]];
}

@end
