/*
 
 File:			PrefsFilter.m
 Program:		KisMAC
 Author:		Michael Ro�berg
                mick@binaervarianz.de
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

#import "PrefsFilter.h"
#import "KisMACNotifications.h"
#import "PrefsController.h"
#import "WaveHelper.h"

@implementation PrefsFilter

- (NSString *)makeValidMACAddress:(NSString *)challenge
{
    const char *c;
    int tmp[6];
    NSString *mac = [[challenge stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    if ([mac length]<11) return nil;
    if ([mac length]>17) return nil;
        
    c = [mac UTF8String];
    if (sscanf(c,"%2X:%2X:%2X:%2X:%2X:%2X", &tmp[0], &tmp[1], &tmp[2], &tmp[3], &tmp[4], &tmp[5]) != 6) return nil;
    
    return [NSString stringWithFormat:@"%.2X%.2X%.2X%.2X%.2X%.2X", tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5]]; 
}

- (NSString *)makeMAC:(NSString *)mac
{
    const char *c;
    int tmp[6];

    c = [mac UTF8String];
    if (sscanf(c,"%2X%2X%2X%2X%2X%2X", &tmp[0], &tmp[1], &tmp[2], &tmp[3], &tmp[4], &tmp[5]) != 6) return @"invalid MAC";
    
    return [NSString stringWithFormat:@"%.2X:%.2X:%.2X:%.2X:%.2X:%.2X", tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5]];
}

- (void)updateUI
{
}

- (IBAction)setValueForSender:(id)sender
{
    if(sender == _newItem)
    {
    }
    else
    {
        DBNSLog(@"Error: Invalid sender(%@) in setValueForSender:",sender);
    }
}

- (IBAction)addItem:(id)sender
{
    NSString *mac;
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:[controller objectForKey:@"FilterBSSIDList"]];
    
    mac = [self makeValidMACAddress:[_newItem stringValue]];
    
    if (!mac)
    {
        NSRunAlertPanel(NSLocalizedString(@"Invalid MAC Address", "for Filter PrefPane"),
            NSLocalizedString(@"Invalid MAC Address description", "LONG description how a MAC looks like"),
            //@"You specified an illegal MAC address. MAC addresses consist of 6 hexvalues seperated by colons.",
            OK, nil, nil);
        
        return;
    }
    else if ([temp indexOfObject:mac] != NSNotFound)
    {
        NSRunAlertPanel(NSLocalizedString(@"MAC Address exsist", "for Filter PrefPane"), 
            NSLocalizedString(@"MAC Address exsist description", "LONG description"),
            //@"You specified a MAC address, which already exists in the list."
            OK, nil, nil);
        
        return;
    }
    
    [temp addObject:mac];
    [controller setObject:temp forKey:@"FilterBSSIDList"];
    [_bssidTable reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KisMACFiltersChanged object:self];
}

- (IBAction)removeItem:(id)sender
{
    NSMutableArray *temp = [NSMutableArray arrayWithArray:[controller objectForKey:@"FilterBSSIDList"]];
    
    for (NSInteger i = [_bssidTable numberOfRows]; i >= 0; i--)
    {
        if ([_bssidTable isRowSelected:i]) {
            [temp removeObjectAtIndex:i];
        }
    }
    
    [controller setObject:temp forKey:@"FilterBSSIDList"];
    [_bssidTable reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:KisMACFiltersChanged object:self];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [self makeMAC:[controller objectForKey:@"FilterBSSIDList"][row]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
   return [[controller objectForKey:@"FilterBSSIDList"] count];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return YES;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *s;
    NSMutableArray *temp = [NSMutableArray arrayWithArray:[controller objectForKey:@"FilterBSSIDList"]];
    
    s = [self makeValidMACAddress:object];
    
    if (s)
    {
        temp[row] = s;
        [controller setObject:temp forKey:@"FilterBSSIDList"];
    }
    
    [tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:KisMACFiltersChanged object:self];
}

@end
