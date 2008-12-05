//
//  ImagePreviewer.h
//  ImagePreviewer
//
//  Created by Jjgod Jiang on 8/18/08.
//  Copyright 2008 Jjgod Jiang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YLBundle.h"

@interface ImagePreviewer : YLBundle {
    BOOL enabled;
}

- (IBAction) flipEnabled: (id) sender;

@end
