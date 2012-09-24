//
//  PrefsDriver.m
//  KisMAC
//
//  Created by Michael Thole on Mon Jan 20 2003.
//  Copyright (c) 2003 Michael Thole. All rights reserved.
//

#import "PrefsDriver.h"
#import "WaveHelper.h"
#import "WaveDriver.h"
#import "WaveDriverAirportExtreme.h"

@implementation PrefsDriver


//updates the driverlist, ignoring multiple drivers, which are allowed to be selected only once
- (void)updateDrivers {
    NSArray *drivers;
    int i = 0;
    unsigned int j;
    NSString *s;
    Class c;
    
    [_driver removeAllItems];
    drivers = [controller objectForKey:@"ActiveDrivers"];
    
    while (WaveDrivers[i][0]) {
        s = [NSString stringWithUTF8String:WaveDrivers[i]];
        for (j = 0; j < [drivers count]; j++) {
            c = NSClassFromString(s);
            
            //check if device exists
            if ([[[drivers objectAtIndex:j] objectForKey:@"driverID"] isEqualToString:s]) break;

            //check if device is in use by some other driver, which is already loaded
            if ([[[drivers objectAtIndex:j] objectForKey:@"deviceName"] isEqualToString:[c deviceName]]) break;
        }
        c = NSClassFromString(s);
        
        if (j == [drivers count] || [c allowsMultipleInstances]) {
            [_driver addItemWithTitle:[NSClassFromString(s) description]];
            [[_driver lastItem] setTag:i];
        }
        i++;
    }
}

-(Class) getCurrentDriver {
    NSDictionary *d;
    int i = [_driverTable selectedRow];
    
    if (i<0) return Nil;
    
    d = [[controller objectForKey:@"ActiveDrivers"] objectAtIndex:i];
    return NSClassFromString([d objectForKey:@"driverID"]);
}

-(NSDictionary*) getCurrentSettings {
	int i = [_driverTable selectedRow];
    
    if (i<0) return Nil;
    
    return [[controller objectForKey:@"ActiveDrivers"] objectAtIndex:i];
}

- (void) updateSettings {
    bool enableAll = NO;
    bool enableChannel = NO;
    bool enableInjection = NO;
    bool enableDumping = NO;
	bool enableIPAndPort = NO;
    Class driverClass;
    NSDictionary *d = Nil;
    unsigned int x, y;
    int val, startCorrect = 0;
    
    [_frequence     setFloatValue:  [[controller objectForKey:@"frequence"   ] floatValue]];

    if ([_driverTable numberOfSelectedRows]) {
        d = [self getCurrentSettings];
        enableAll = YES;

        driverClass = [self getCurrentDriver];
        if ([driverClass allowsChannelHopping]) enableChannel = YES;
        if ([driverClass allowsInjection]) enableInjection = YES;
        if ([driverClass type] == passiveDriver) enableDumping = YES;
		if ([driverClass wantsIPAndPort]) enableIPAndPort = YES;
		if (enableIPAndPort) {
			[_chanhop setHidden:true];
			[_kdrone_settings setHidden:false];
			[_kismet_host setStringValue:[d objectForKey:@"kismetserverhost"]];
			[_kismet_port setIntValue:[[d objectForKey:@"kismetserverport"] intValue]];
		} else {
			[_chanhop setHidden:false];
			[_kdrone_settings setHidden:true];
		}
        
    }
    
    [_removeDriver  setEnabled:enableAll];
    
    [_selAll        setEnabled:enableChannel];
    [_selNone       setEnabled:enableChannel];
    [_channelSel    setEnabled:enableChannel];
    [_firstChannel  setEnabled:enableChannel];
	    
    [_dumpDestination       setEnabled:enableDumping];
    [_dumpFilter            setEnabled:enableDumping];
    
    [_injectionDevice        setEnabled:enableInjection];
    if (!enableInjection) {
		[_injectionDevice setTitle:@"Injection Not Supported"];
    }else
        [_injectionDevice setTitle:@"use as primary device"];
    
    if (enableChannel) {
        [_firstChannel  setIntValue:    [[d objectForKey:@"firstChannel"] intValue]];

        for (x = 0; x<2; x++) 
            for (y = 0; y < 7; y++) {
                val = [[d objectForKey:[NSString stringWithFormat:@"useChannel%.2i",(x*7+y+1)]] boolValue] ? NSOnState : NSOffState;
                [[_channelSel cellAtRow:y column:x] setState:val];
                if (x*7+y+1 == [_firstChannel intValue]) startCorrect = val;
            }
        
        if (startCorrect==0) {
            for (x = 0; x<2; x++) {
                for (y = 0; y < 7; y++) {
                    val = [[d objectForKey:[NSString stringWithFormat:@"useChannel%.2i",(x*7+y+1)]] boolValue] ? NSOnState : NSOffState;
                    if (val) {  
                        [_firstChannel setIntValue:x*7+y+1];
                        break;
                    }
                }
                if (y!=7) break;
            }
        }
    } else {
        for (x = 0; x<2; x++) 
            for (y = 0; y < 7; y++)
                [[_channelSel cellAtRow:y column:x] setState:NSOffState];

        
        [_firstChannel  setIntValue:   1];
    }
    
    if (enableInjection) {
        [_injectionDevice setState: [[d objectForKey:@"injectionDevice"] intValue]];
    } else {
        [_injectionDevice setState: NSOffState];
    }
    
    if (enableDumping) {
       [_dumpDestination setStringValue:[d objectForKey:@"dumpDestination"]];
       [_dumpFilter selectCellAtRow:[[d objectForKey:@"dumpFilter"] intValue] column:0];
       [_dumpDestination setEnabled:[[d objectForKey:@"dumpFilter"] intValue] ? YES : NO];
    } else {
       [_dumpDestination setStringValue:@"~/DumpLog %y-%m-%d %H:%M"];
       [_dumpFilter selectCellAtRow:0 column:0];
       [_dumpDestination setEnabled:NO];
    }
}

-(BOOL)updateInternalSettings:(BOOL)warn {
    NSMutableDictionary *d;
    NSMutableArray *a;
    WaveDriver *wd;
    int i = [_driverTable selectedRow];
    int val = 0, startCorrect = 0;
    unsigned int x, y;
	
    [controller setObject:[NSNumber numberWithFloat: [_frequence     floatValue]]    forKey:@"frequence"];
    if (i < 0) return YES;
    d = [[self getCurrentSettings] mutableCopy];
    if (!d) return YES;
    
    if ([[self getCurrentDriver] allowsChannelHopping]) {
        for (x = 0; x<2; x++) 
            for (y = 0; y < 7; y++) {
                val+=[[_channelSel cellAtRow:y column:x] state];
                if (x*7+y+1 == [_firstChannel intValue]) startCorrect = [[_channelSel cellAtRow:y column:x] state];
            }    
        
        if (warn && (val == 0 || startCorrect == 0)) {
            NSRunAlertPanel(NSLocalizedString(@"Invalid Option", "Invalid channel selection failure title"),
                            NSLocalizedString(@"Invalid channel selection failure title", "LONG Error description"),
                            //@"You have to select at least one channel, otherwise scanning makes no sense. Also please make sure that you have selected "
                            //"a valid start channel.",
                            OK,nil,nil);
            [d release];
            return NO;
        }
    }

    for (x = 0; x<2; x++) 
        for (y = 0; y < 7; y++) {
            val = [[_channelSel cellAtRow:y column:x] state];
            [d setObject:[NSNumber numberWithBool: val ? YES : NO] forKey:[NSString stringWithFormat:@"useChannel%.2i",(x*7+y+1)]];
        }
    
    [d setObject:[NSNumber numberWithInt:   [_firstChannel  intValue]]      forKey:@"firstChannel"];
    
    [d setObject:[NSNumber numberWithBool:  [_injectionDevice state] ? YES : NO] forKey:@"injectionDevice"];
    
    [d setObject:[_dumpDestination stringValue] forKey:@"dumpDestination"];
    [d setObject:[NSNumber numberWithInt:[_dumpFilter selectedRow]] forKey:@"dumpFilter"];
    
	[d setObject:[_kismet_host stringValue] forKey:@"kismetserverhost"];
	[d setObject:[NSNumber numberWithInt:[_kismet_port intValue]] forKey:@"kismetserverport"];
	
    a = [[controller objectForKey:@"ActiveDrivers"] mutableCopy];
    [a replaceObjectAtIndex:i withObject:d];
    [controller setObject:a forKey:@"ActiveDrivers"];
    
    wd = [WaveHelper driverWithName:[d objectForKey:@"deviceName"]];
    [wd setConfiguration:d];
    
    [d release];
    [a release];
    
    return YES;
}

#pragma mark -

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[controller objectForKey:@"ActiveDrivers"] count];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex {     
    return [NSClassFromString([[[controller objectForKey:@"ActiveDrivers"] objectAtIndex: rowIndex] objectForKey:@"driverID"]) description]; 
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self updateSettings];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row {
    return [self updateInternalSettings:YES];
}

#pragma mark -

-(void)updateUI {
    [self updateDrivers];
    [self updateSettings];
}

-(BOOL)updateDictionary {
    return [self updateInternalSettings:YES];
}

-(IBAction)setValueForSender:(id)sender {
    [self updateInternalSettings:NO];
    [self updateSettings];
}

#pragma mark -

- (IBAction)selAddDriver:(id)sender {
    NSMutableArray *drivers;
    NSString *driverClassName;
	NSNumber *kserverport;
    
    driverClassName = [NSString stringWithUTF8String:WaveDrivers[[[_driver selectedItem] tag]]];
    
	if ([driverClassName isEqualToString:@"WaveDriverKismet"]) {
		kserverport = [NSNumber numberWithInt:2501];
	} else if ([driverClassName isEqualToString:@"WaveDriverKismetDrone"]) {
		kserverport = [NSNumber numberWithInt:3501];
	} else {
		kserverport = [NSNumber numberWithInt:0];
	}
	
    drivers = [[controller objectForKey:@"ActiveDrivers"] mutableCopy];
    [drivers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        driverClassName, @"driverID",
        [NSNumber numberWithInt: 1]     , @"firstChannel",
        [NSNumber numberWithBool: YES]  , @"useChannel01",
        [NSNumber numberWithBool: YES]  , @"useChannel02",
        [NSNumber numberWithBool: YES]  , @"useChannel03",
        [NSNumber numberWithBool: YES]  , @"useChannel04",
        [NSNumber numberWithBool: YES]  , @"useChannel05",
        [NSNumber numberWithBool: YES]  , @"useChannel06",
        [NSNumber numberWithBool: YES]  , @"useChannel07",
        [NSNumber numberWithBool: YES]  , @"useChannel08",
        [NSNumber numberWithBool: YES]  , @"useChannel09",
        [NSNumber numberWithBool: YES]  , @"useChannel10",
        [NSNumber numberWithBool: YES]  , @"useChannel11",
        [NSNumber numberWithBool: NO]   , @"useChannel12",
        [NSNumber numberWithBool: NO]   , @"useChannel13",
        [NSNumber numberWithBool: NO]   , @"useChannel14",
        [NSNumber numberWithInt: 0]     , @"injectionDevice",
        [NSNumber numberWithInt: 0]     , @"dumpFilter",
        @"~/DumpLog %y-%m-%d %H:%M"    , @"dumpDestination",
        [NSClassFromString(driverClassName) deviceName], @"deviceName", //todo make this unique for ever instance
		@"127.0.0.1", @"kismetserverhost",
		kserverport, @"kismetserverport",
        nil]];
    [controller setObject:drivers forKey:@"ActiveDrivers"];
    
    [_driverTable reloadData];
    [_driverTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[drivers count]-1]
              byExtendingSelection:NO];
	[self updateUI];
    [drivers release];
}

- (IBAction)selRemoveDriver:(id)sender {
    int i;
    NSMutableArray *drivers;
    
    i = [_driverTable selectedRow];
    if (i < 0) return;
    
    drivers = [[controller objectForKey:@"ActiveDrivers"] mutableCopy];
    [drivers removeObjectAtIndex:i];
    [controller setObject:drivers forKey:@"ActiveDrivers"];    
    
    [_driverTable reloadData];
    [self updateUI];
    [drivers release];
}

- (IBAction)selAll:(id)sender {
    [_channelSel selectAll:self];
    [self setValueForSender:_channelSel];
}

- (IBAction)selNone:(id)sender {
    [_channelSel deselectAllCells];
    [self setValueForSender:_channelSel];
}


@end
