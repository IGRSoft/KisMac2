/*
        
        File:			PrefsController.m
        Program:		KisMAC
	Author:			Michael Thole
	Description:		KisMAC is a wireless stumbler for MacOS X.
                
        This file is part of KisMAC.

    KisMAC is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License, version 2,
    as published by the Free Software Foundation;

    KisMAC is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with KisMAC; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
#import "PrefsController.h"
#import "KisMACNotifications.h"

void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=nil)
    {
        // we actually need an NSMenuItem here, so we construct one
        mItem=[[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu: menu];
        [mItem setTitle: [menu title]];
        [item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

@implementation PrefsController

- (id)init {
    prefsToolbar=[[NSToolbar alloc] initWithIdentifier:@"prefsToolbar"];
    [prefsToolbar setDelegate:self];
    [prefsToolbar setAllowsUserCustomization:NO];
    
    toolbarItems = [[NSMutableDictionary alloc] init];
    nibNamesDict = [[NSMutableDictionary alloc] init];
    classNamesDict = [[NSMutableDictionary alloc] init];
    
    [nibNamesDict setObject:@"PrefsScanning" forKey:@"Scanning"];
    [classNamesDict setObject:@"PrefsScanning" forKey:@"Scanning"];
    addToolbarItem(toolbarItems,
                   @"Scanning",
                   @"Scanning",
                   @"Scanning",
                   @"Scanning Options",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"NSApplicationIcon"],
                   @selector(changeView:),
                   nil);
    defaultToolbarItem = [toolbarItems objectForKey:@"Scanning"];

    [nibNamesDict setObject:@"PrefsTraffic" forKey:@"Traffic"];
    [classNamesDict setObject:@"PrefsTraffic" forKey:@"Traffic"];
    addToolbarItem(toolbarItems,
                   @"Traffic",
                   @"Traffic",
                   @"Traffic",
                   @"Traffic View Options",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"traffic"],
                   @selector(changeView:),
                   nil);

    [nibNamesDict setObject:@"PrefsFilter" forKey:@"Filter"];
    [classNamesDict setObject:@"PrefsFilter" forKey:@"Filter"];
    addToolbarItem(toolbarItems,
                   @"Filter",
                   @"Filter",
                   @"Filter",
                   @"Filter Options for Data Capture",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"filter"],
                   @selector(changeView:),
                   nil);


    [nibNamesDict setObject:@"PrefsSounds" forKey:@"Sounds"];
    [classNamesDict setObject:@"PrefsSounds" forKey:@"Sounds"];
    addToolbarItem(toolbarItems,
                   @"Sounds",
                   @"Sounds",
                   @"Sounds",
                   @"Sounds and Speech Options",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"Sound"],
                   @selector(changeView:),
                   nil);

    [nibNamesDict setObject:@"PrefsDriver" forKey:@"Driver"];
    [classNamesDict setObject:@"PrefsDriver" forKey:@"Driver"];
    addToolbarItem(toolbarItems,
                   @"Driver",
                   @"Driver",
                   @"Driver",
                   @"Wireless Card Driver",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"KisMAC"],
                   @selector(changeView:),
                   nil);

    [nibNamesDict setObject:@"PrefsGPS" forKey:@"GPS"];
    [classNamesDict setObject:@"PrefsGPS" forKey:@"GPS"];
    addToolbarItem(toolbarItems,
                   @"GPS",
                   @"GPS",
                   @"GPS",
                   @"GPS Options",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"gps"],
                   @selector(changeView:),
                   nil);
    [nibNamesDict setObject:@"PrefsMap" forKey:@"Map"];
    [classNamesDict setObject:@"PrefsMap" forKey:@"Map"];
    addToolbarItem(toolbarItems,
                   @"Map",
                   @"Map",
                   @"Map",
                   @"Mapping Options",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"map"],
                   @selector(changeView:),
                   nil);
	
	[nibNamesDict setObject:@"PrefsAdvanced" forKey:@"Advanced"];
    [classNamesDict setObject:@"PrefsAdvanced" forKey:@"Advanced"];
    addToolbarItem(toolbarItems,
                   @"Advanced",
                   @"Advanced",
                   @"Advanced",
                   @"Advanced Options",
                   self,
                   @selector(setImage:),
                   [NSImage imageNamed:@"EnergySaver"],
                   @selector(changeView:),
                   nil);

    changesDict = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)awakeFromNib {
    [prefsWindow setTitle:@"KisMAC Preferences"];
    [prefsWindow setToolbar:prefsToolbar];
    [prefsWindow center];
    [self changeView:defaultToolbarItem];
}

#pragma mark -

- (void)changeView:(NSToolbarItem*)sender 
{
    int i, count;
    NSString* nibName = nil;
    NSString* className = nil;
    NSArray* itemsArray = [prefsToolbar items];
    NSView* contentView, *oldView, *controlBox;
    NSRect controlBoxFrame;
    NSRect windowFrame;
    int newWindowHeight;
    NSRect newWindowFrame;

    // TODO make this more error proof

    if(currentToolbarItem == sender) {
        [currentClient updateUI];
        return;
    }
    
    count = [itemsArray count];

    if (currentClient&&(![currentClient updateDictionary])) return;
    
    for(i = 0 ; i < count ; i++) {
        if([[[itemsArray objectAtIndex:i] itemIdentifier] isEqualToString:[sender itemIdentifier]]) {
            nibName = [nibNamesDict objectForKey:[[itemsArray objectAtIndex:i] itemIdentifier]];
            className = [classNamesDict objectForKey:[[itemsArray objectAtIndex:i] itemIdentifier]];
            currentToolbarItem = sender;
            break;
        }
    }

    contentView = [prefsBox contentView];
    oldView = [[contentView subviews] lastObject];
    [oldView removeFromSuperview];

    [currentClient release];
    currentClient = [[[[NSBundle mainBundle] classNamed:className] alloc] init];
    [currentClient setController:defaults];
    
    [NSBundle loadNibNamed:nibName owner:currentClient];

    controlBox = [currentClient controlBox];
    controlBoxFrame = controlBox != nil ? [controlBox frame] : NSZeroRect;

    windowFrame = [NSWindow contentRectForFrameRect:[prefsWindow frame] styleMask:[prefsWindow styleMask]];
    newWindowHeight = NSHeight(controlBoxFrame) + 10;
    newWindowHeight += NSHeight([[prefsToolbar _toolbarView] frame]);
    //newWindowHeight += 43;
    newWindowFrame = [NSWindow frameRectForContentRect:NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - newWindowHeight, NSWidth(windowFrame), newWindowHeight) styleMask:[prefsWindow styleMask]];
    [prefsWindow setFrame:newWindowFrame display:YES animate:[prefsWindow isVisible]];    
    [controlBox setFrameOrigin:NSMakePoint(floor((NSWidth([contentView frame]) - NSWidth(controlBoxFrame)) / 2.0),
                                           floor(NSHeight([contentView frame]) - NSHeight(controlBoxFrame)))];
    
    [currentClient updateUI];
    [contentView addSubview:controlBox];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KisMACUserDefaultsChanged object:self];
}

#pragma mark -


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"Scanning", @"Filter", @"Sounds", @"Driver", @"GPS", @"Map", @"Traffic", @"Advanced", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item = nil;

    item=[toolbarItems objectForKey:itemIdentifier];

    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=nil)
    {
        [newItem setView:[item view]];
    }
    else
    {
        [newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=nil)
    {
        [newItem setMinSize:[[item view] bounds].size];
        [newItem setMaxSize:[[item view] bounds].size];
    }
    return newItem;
}

#pragma mark -

- (id)objectForKey:(NSString*)key {
    id object = [changesDict objectForKey:key];
    if(object) return object;
    
    object = [defaults objectForKey:key];
    if(!object) NSLog(@"Error: -[PrefsController objectForKey:%@] returning NULL!", key);
    return object;
}

- (void)setObject:(id)object forKey:(NSString*)key {
    [changesDict setObject:object forKey:key];
}

- (NSWindow*)window {
    return prefsWindow;
}

#pragma mark -

- (IBAction)refreshUI:(id)sender {
    [currentClient updateUI];
}

- (IBAction)clickOk:(id)sender
{
    if (![currentClient updateDictionary]) return;
    
    [prefsWindow close];
    [changesDict removeAllObjects];
    [currentClient updateUI];
}

- (IBAction)clickCancel:(id)sender {
    [prefsWindow close];
    [changesDict removeAllObjects];
    [currentClient updateUI];
}

- (BOOL)windowShouldClose:(id)sender {
    return [currentClient updateDictionary];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [currentClient updateDictionary];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:KisMACUserDefaultsChanged object:self];
}

#pragma mark -

- (void)dealloc {
    [toolbarItems release];
    [nibNamesDict release];
    [classNamesDict release];
    [changesDict release];
    
    [super dealloc];
}

@end