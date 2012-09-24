//
//  BIView.m
//  BIGeneric
//
//  Created by mick on Fri Jul 02 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BIToolbarView.h"


@implementation BIToolbarView

- (void)drawRect:(NSRect)rect {
    int i;
    [[NSColor colorWithDeviceRed:180.0/255.0 green:192.0/255.0 blue:1 alpha:1] set];
    NSRectFill(rect);

    NSColor *color = [NSColor colorWithDeviceRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:1];
    [color set];

    NSRectFill(NSMakeRect(0,0,_frame.size.width,1));
    NSRectFill(NSMakeRect(0,_frame.size.height-1,_frame.size.width,1));
    
    rect.origin.x = (int)rect.origin.x + 50 - ((int)rect.origin.x % 50);
    for (i = rect.origin.x; i < rect.size.width + rect.origin.x; i+=50) {
        NSRectFill(NSMakeRect(rect.origin.x + i,rect.origin.y, 1, rect.size.height));
    }
    
    if (![NSImage imageNamed:@"BIToolbar.tif"]) NSLog(@"no image");
    [[NSImage imageNamed:@"BIToolbar.tif"] dissolveToPoint:NSMakePoint(0,0) fraction:1.0];
}

@end
