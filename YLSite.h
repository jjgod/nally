//
//  YLSite.h
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/20/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommonType.h"

@interface YLSite : NSObject {
    NSString *_name;
    NSString *_address;
    YLEncoding _encoding;
}

+ (YLSite *) siteWithDictionary: (NSDictionary *) d ;
- (NSDictionary *) dictionaryOfSite ;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)address;
- (void)setAddress:(NSString *)value;

- (YLEncoding)encoding;
- (void)setEncoding:(YLEncoding)encoding;

@end
