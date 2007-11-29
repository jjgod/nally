//
//  YLApplication.m
//  MacBlueTelnet
//
//  Created by Lan Yung-Luen on 11/17/07.
//  Copyright 2007 yllan.org. All rights reserved.
//

#import "YLApplication.h"


@implementation YLApplication
- (void) sendEvent: (NSEvent *) event {
    if ([event type] == NSKeyDown) {
        unichar right = NSRightArrowFunctionKey;
        unichar left = NSLeftArrowFunctionKey;
        NSString *rightString = [NSString stringWithCharacters: &right length: 1];
        NSString *leftString = [NSString stringWithCharacters: &left length: 1];
        if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
            (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
            [[event charactersIgnoringModifiers] isEqualToString: rightString] ) {

            event = [NSEvent keyEventWithType: [event type] 
                                     location: [event locationInWindow] 
                                modifierFlags: [event modifierFlags] ^ NSShiftKeyMask
                                    timestamp: [event timestamp] 
                                 windowNumber: [event windowNumber] 
                                      context: [event context] 
                                   characters: rightString
                  charactersIgnoringModifiers: rightString 
                                    isARepeat: [event isARepeat] 
                                      keyCode:[event keyCode]];
        } else if ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) && 
                    (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) &&
                    [[event charactersIgnoringModifiers] isEqualToString: leftString] ) {
            
            event = [NSEvent keyEventWithType: [event type] 
                                     location: [event locationInWindow] 
                                modifierFlags: [event modifierFlags] ^ NSShiftKeyMask
                                    timestamp: [event timestamp] 
                                 windowNumber: [event windowNumber] 
                                      context: [event context] 
                                   characters: leftString
                  charactersIgnoringModifiers: leftString 
                                    isARepeat: [event isARepeat] 
                                      keyCode:[event keyCode]];
        }
        
    }
    
    [super sendEvent:event];
}


@end
