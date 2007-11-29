//
//  YLSite.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface YLSite : NSObject {
    NSString *_name;
    NSString *_address;
}

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)address;
- (void)setAddress:(NSString *)value;


@end
