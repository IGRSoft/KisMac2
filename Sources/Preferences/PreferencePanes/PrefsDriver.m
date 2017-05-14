/*
 
 File:			PrefsDriver.m
 Program:		KisMAC
 Author:		Michael Thole
 Changes:       Vitalii Parovishnyk(1012-2015)
 
 Description:	KisMAC is a wireless stumbler for MacOS X.
 
 This file is part of KisMAC.
 
 Most parts of this file are based on aircrack by Christophe Devine.
 
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

#import "PrefsDriver.h"
#import "PrefsController.h"
#import "WaveHelper.h"
#import "WaveDriver.h"
#import "WaveDriverAirportExtreme.h"

@implementation PrefsDriver

#define Chanel24Row     2
#define Chanel24Column  7

#define Max24GhzChannels  14
#define Max50GhzChannels 165

//updates the driverlist, ignoring multiple drivers, which are allowed to be selected only once
- (void)updateDrivers
{
    NSArray *drivers;
    NSInteger i = 0;
    NSUInteger j;
    NSString *s;
    Class c;
    
    [_driver removeAllItems];
    drivers = [controller objectForKey:@"ActiveDrivers"];
    
    while (WaveDrivers[i][0])
    {
        s = @(WaveDrivers[i]);
        for (j = 0 ; j < [drivers count] ; ++j)
        {
            c = NSClassFromString(s);
            
            //check if device exists
            if ([drivers[j][@"driverID"] isEqualToString:s])
                break;
            
            //check if device is in use by some other driver, which is already loaded
            if ([drivers[j][@"deviceName"] isEqualToString:[c deviceName]])
                break;
        }
        c = NSClassFromString(s);
        
        if (j == [drivers count] || [c allowsMultipleInstances])
        {
            [_driver addItemWithTitle:[NSClassFromString(s) description]];
            [[_driver lastItem] setTag:i];
        }
        ++i;
    }
}

- (Class) getCurrentDriver
{
    NSDictionary *d;
    NSInteger i = [_driverTable selectedRow];
    
    if (i < 0)
        return Nil;
    
    d = [controller objectForKey:@"ActiveDrivers"][i];
    return NSClassFromString(d[@"driverID"]);
}

- (NSDictionary*) getCurrentSettings
{
    NSInteger i = [_driverTable selectedRow];
    
    if ( i < 0 ) return nil;
    
    return [controller objectForKey:@"ActiveDrivers"][i];
}

- (void) updateSettings
{
    BOOL enableAll = NO;
    BOOL enableChannel = NO;
    BOOL enableInjection = NO;
    BOOL enableDumping = NO;
    BOOL enableIPAndPort = NO;
    Class driverClass;
    NSDictionary *d = nil;
    NSUInteger x, y;
    
    [_frequence setFloatValue:[[controller objectForKey:@"frequence"] floatValue]];
    
    if ([_driverTable numberOfSelectedRows])
    {
        d = [self getCurrentSettings];
        enableAll = YES;
        
        driverClass = [self getCurrentDriver];
        if ([driverClass allowsChannelHopping])
            enableChannel = YES;
        
        if ([driverClass allowsInjection])
            enableInjection = YES;
        
        if ([driverClass type] == passiveDriver)
            enableDumping = YES;
        
        if ([driverClass wantsIPAndPort])
            enableIPAndPort = YES;
        
        if (enableIPAndPort)
        {
            [_chanhop setHidden:YES];
            [_kdrone_settings setHidden:NO];
            [_kismet_host setStringValue:d[@"kismetserverhost"]];
            [_kismet_port setIntValue:[d[@"kismetserverport"] intValue]];
        }
        else
        {
            [_chanhop setHidden:NO];
            [_kdrone_settings setHidden:YES];
        }
    }
    
    [_removeDriver          setEnabled:enableAll];
    [_selAll                setEnabled:enableChannel];
    [_selNone               setEnabled:enableChannel];
    [_channelSel            setEnabled:enableChannel];
    [_firstChannel          setEnabled:enableChannel];
    [_use24GHzChannels       setEnabled:enableChannel];
    [_use50GHzChannels       setEnabled:enableChannel];
    [_useAll50GHzChannels	setEnabled:enableChannel];
    [_useRange50GHzChannels	setEnabled:enableChannel];
    [_range50GHzChannels     setEnabled:enableChannel];
    [_dumpDestination       setEnabled:enableDumping];
    [_dumpFilter            setEnabled:enableDumping];
    [_injectionDevice       setEnabled:enableInjection];
    
    if (!enableInjection)
    {
        [_injectionDevice setTitle:@"Injection Not Supported"];
    }
    else
    {
        [_injectionDevice setTitle:@"use as primary device"];
    }
    
    for (x = 0 ; x < Chanel24Row ; ++x)
    {
        for (y = 0 ; y < Chanel24Column ; ++y)
        {
            [[_channelSel cellAtRow:y column:x] setState:NSOffState];
        }
    }
    
    if (enableChannel)
    {
        [_firstChannel  setIntValue:[d[@"firstChannel"] intValue]];
        
        NSArray *useChannels = d[@"useChannels"];
        for (NSNumber *useChannel in useChannels)
        {
            NSInteger useChannelVal = useChannel.integerValue;
            
            if (useChannelVal > Max24GhzChannels)
            {
                continue;
            }
            
            NSInteger column = (useChannelVal - 1) / Chanel24Column;
            NSInteger row = (useChannelVal - 1) % Chanel24Column;
            
            [[_channelSel cellAtRow:row column:column] setState:NSOnState];
        }
    }
    else
    {
        [_firstChannel  setIntValue: 1];
    }
    
    BOOL use24GHzChannels = [d[@"use24GHzChannels"] boolValue];
    BOOL use50GHzChannels = [d[@"use50GHzChannels"] boolValue];
    
    [_use24GHzChannels setState:use24GHzChannels ? NSOnState : NSOffState];
    [_use50GHzChannels setState:use50GHzChannels ? NSOnState : NSOffState];
    
    [_useAll50GHzChannels setState:[d[@"useAll50GHzChannels"] boolValue] ? NSOnState : NSOffState];
    [_useRange50GHzChannels setState:[d[@"useRange50GHzChannels"] boolValue] ? NSOnState : NSOffState];
    [_useRange50GHzChannels setStringValue:d[@"range50GHzChannels"] ?: @""];
    
    if (enableInjection)
    {
        [_injectionDevice setState: [d[@"injectionDevice"] intValue]];
    }
    else
    {
        [_injectionDevice setState: NSOffState];
    }
    
    if (enableDumping)
    {
        [_dumpDestination	setStringValue:d[@"dumpDestination"]];
        [_dumpFilter		selectCellAtRow:[d[@"dumpFilter"] intValue] column:0];
        [_dumpDestination	setEnabled:[d[@"dumpFilter"] intValue] ? YES : NO];
    }
    else
    {
        [_dumpDestination	setStringValue:@"~/DumpLog %y-%m-%d %H:%M"];
        [_dumpFilter		selectCellAtRow:0 column:0];
        [_dumpDestination	setEnabled:NO];
    }
}

- (BOOL)updateInternalSettings:(BOOL)warn
{
    NSMutableDictionary *d;
    NSMutableArray *a;
    WaveDriver *wd;
    NSInteger i = [_driverTable selectedRow];
    NSUInteger x, y;
    
    [controller setObject:@([_frequence     floatValue])    forKey:@"frequence"];
    if (i < 0)
        return YES;
    
    d = [[self getCurrentSettings] mutableCopy];
    if (!d)
    {
        return YES;
    }
    
    BOOL use24GHzChannels = [_use24GHzChannels state] ? YES : NO;
    BOOL use50GHzChannels = [_use50GHzChannels state] ? YES : NO;
    
    NSMutableArray *useChannel = [NSMutableArray array];
    
    if (use24GHzChannels)
    {
        for (x = 0 ; x < Chanel24Row ; ++x)
        {
            for (y = 0 ; y < Chanel24Column ; ++y)
            {
                if ([[_channelSel cellAtRow:y column:x] state] == NSOnState)
                {
                    [useChannel addObject:@(Chanel24Column*x+y+1)];
                }
            }
        }
    }
    
    if (use50GHzChannels)
    {
        [useChannel addObjectsFromArray:[self get50GhzChannels]];
    }
    
    if ([[self getCurrentDriver] allowsChannelHopping])
    {
        BOOL startCorrect = NO;
        
        for (NSNumber *channel in useChannel)
        {
            if (channel.integerValue >= _firstChannel.integerValue)
            {
                startCorrect = YES;
            }
        }
        
        if (warn && !startCorrect)
        {
            NSRunAlertPanel(NSLocalizedString(@"Invalid Option", "Invalid channel selection failure title"),
                            NSLocalizedString(@"Invalid channel selection failure title", "LONG Error description"),
                            //@"You have to select at least one channel, otherwise scanning makes no sense. Also please make sure that you have selected "
                            //"a valid start channel.",
                            OK,nil,nil);
            return NO;
        }
    }
    
    d[@"use24GHzChannels"]       = @(use24GHzChannels);
    d[@"use50GHzChannels"]       = @(use50GHzChannels);
    
    d[@"useAll50GHzChannels"]	= [_useAll50GHzChannels state] ? @YES : @NO;
    d[@"useRange50GHzChannels"]	= [_useRange50GHzChannels state] ? @YES : @NO;
    d[@"range50GHzChannels"]    = _range50GHzChannels.stringValue;
    
    d[@"useChannels"]           = useChannel;
    
    d[@"firstChannel"]          = @([_firstChannel intValue]);
    
    d[@"injectionDevice"]       = [_injectionDevice state] ? @YES : @NO;
    
    d[@"dumpDestination"]       = [_dumpDestination stringValue];
    d[@"dumpFilter"]            = @([_dumpFilter selectedRow]);
    
    d[@"kismetserverhost"]      = [_kismet_host stringValue];
    d[@"kismetserverport"]      = @([_kismet_port intValue]);
    
    a = [[controller objectForKey:@"ActiveDrivers"] mutableCopy];
    a[i] = d;
    [controller setObject:a forKey:@"ActiveDrivers"];
    
    wd = [WaveHelper driverWithName:d[@"deviceName"]];
    [wd setConfiguration:d];
    
    return YES;
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[controller objectForKey:@"ActiveDrivers"] count];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    return [NSClassFromString([controller objectForKey:@"ActiveDrivers"][rowIndex][@"driverID"]) description];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self updateSettings];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return [self updateInternalSettings:YES];
}

#pragma mark -

- (void)updateUI
{
    [self updateDrivers];
    [self updateSettings];
}

- (BOOL)updateDictionary
{
    return [self updateInternalSettings:YES];
}

- (IBAction)setValueForSender:(id)sender
{
    [self updateInternalSettings:NO];
    [self updateSettings];
}

#pragma mark -
static NSSet *GetValid5GHzChannels()
{
    static NSSet *Valid5GHzChannels = nil;
    if ( Valid5GHzChannels == nil )
        Valid5GHzChannels = [NSSet setWithObjects:
                         // List taken from: https://en.wikipedia.org/wiki/List_of_WLAN_channels
                         // It should be intersected with what the driver considers valid.
                         @(7), @(8), @(9), @(11), @(12), @(16), @(34), @(36), @(38), @(40),
                         @(42), @(44), @(46), @(48), @(52), @(56), @(60), @(64), @(100),
                         @(104), @(108), @(112), @(116), @(120), @(124), @(128), @(132),
                         @(136), @(140), @(144), @(149), @(153), @(157), @(161), @(165), nil];
    return Valid5GHzChannels;
}

- (IBAction)selAddDriver:(id)sender
{
    NSMutableArray *drivers;
    NSString *driverClassName;
    NSNumber *kserverport;
    
    driverClassName = @(WaveDrivers[[[_driver selectedItem] tag]]);
    
    if ([driverClassName isEqualToString:@"WaveDriverKismet"])
    {
        kserverport = @2501;
    }
    else if ([driverClassName isEqualToString:@"WaveDriverKismetDrone"])
    {
        kserverport = @3501;
    }
    else
    {
        kserverport = @0;
    }
    
    drivers = [[controller objectForKey:@"ActiveDrivers"] mutableCopy];
    
    NSSet *ValidChannels = GetValid5GHzChannels();
    NSMutableArray *useChannels = [NSMutableArray array];
    for (NSUInteger i = 1; i <= Max50GhzChannels; ++i)
    {
        if ( i < 12 || (i > 14 && [ValidChannels containsObject: @(i)]) )
            [useChannels addObject:@(i)];
    }
    
    [drivers addObject:@{
                         @"driverID":               driverClassName,
                         @"firstChannel":           @1,
                         @"useChannels":            useChannels,
                         @"use24GHzChannels":       @YES,
                         @"use50GHzChannels":       @NO,
                         @"useAll50GHzChannels":	@NO,
                         @"useRange50GHzChannels":	@NO,
                         @"range50GHzChannels":     @"",
                         @"injectionDevice":        @0,
                         @"dumpFilter":             @0,
                         @"dumpDestination":        @"~/DumpLog %y-%m-%d %H:%M",
                         @"deviceName":             [NSClassFromString(driverClassName) deviceName], //todo make this unique for ever instance
                         @"kismetserverhost":       @"127.0.0.1",
                         @"kismetserverport":       kserverport
                         }
     ];
    [controller setObject:drivers forKey:@"ActiveDrivers"];
    
    [_driverTable reloadData];
    [_driverTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[drivers count]-1]
              byExtendingSelection:NO];
    [self updateUI];
}

- (IBAction)selRemoveDriver:(id)sender
{
    NSInteger i;
    NSMutableArray *drivers;
    
    i = [_driverTable selectedRow];
    if (i < 0)
        return;
    
    drivers = [[controller objectForKey:@"ActiveDrivers"] mutableCopy];
    [drivers removeObjectAtIndex:i];
    [controller setObject:drivers forKey:@"ActiveDrivers"];    
    
    [_driverTable reloadData];
    [self updateUI];
}

- (IBAction)selAll:(id)sender
{
    [_channelSel selectAll:self];
    [self setValueForSender:_channelSel];
}

- (IBAction)selNone:(id)sender
{
    [_channelSel deselectAllCells];
    [self setValueForSender:_channelSel];
}

- (NSArray *)get50GhzChannels
{
    NSMutableSet *Channels = [NSMutableSet set];
    NSSet *ValidChannels = GetValid5GHzChannels();

    if ([_useAll50GHzChannels state] == NSOnState)
    {
        for (NSUInteger i = Max24GhzChannels + 1; i <= Max50GhzChannels; ++i)
        {
            if ( [ValidChannels containsObject: @(i)] )
                [Channels addObject:@(i)];
        }
    }
    if ([_useRange50GHzChannels state] == NSOnState)
    {
        NSArray *components = [_range50GHzChannels.stringValue componentsSeparatedByString:@","];
        for (NSString *component in components)
        {
            NSArray *innerComponents = [component componentsSeparatedByString:@"-"];
            if (innerComponents.count == 2)
            {
                NSUInteger startChanel = [innerComponents[0] integerValue];
                NSUInteger endChanel = [innerComponents[1] integerValue];
                
                for (NSUInteger i = startChanel; i <= endChanel; ++i)
                {
                    if ( [ValidChannels containsObject: @(i)] )
                        [Channels addObject:@(i)];
                }
            }
            else
            {
                NSInteger i = [component integerValue];
                if ( i > 0 && [ValidChannels containsObject: @(i)] )
                    [Channels addObject:@(i)];
            }
        }
    }
    return [Channels allObjects];
}

@end
