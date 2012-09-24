//
//  PrefsClient.m
//  KisMAC
//
//  Created by Michael Thole on Mon Jan 20 2003.
//  Copyright (c) 2003 Michael Thole. All rights reserved.
//

#import "PrefsClient.h"


@implementation PrefsClient

 - (id)init {
    controller = nil;
    return self;
}

- (void)setController:(id)newController {
    [controller autorelease];
    controller = [newController retain];
}

#pragma mark -

- (void)setValueForSender:(id)sender {
    // implemented by subclasses
}

- (void)updateUI {
    // implemented by subclasses
}

- (BOOL)updateDictionary {
    // implemented by subclasses
    return true;
}

#pragma mark -

- (NSView*)controlBox {
    return controlBox;
}

#pragma mark -

- (void)dealloc {
    [controller release];
    [super dealloc];
}

@end
