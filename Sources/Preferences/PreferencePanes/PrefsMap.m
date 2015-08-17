/*
 
 File:			PrefsMap.m
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

#import "PrefsMap.h"
#import "WaveHelper.h"
#import "PrefsController.h"

@implementation PrefsMap

- (void)updateUI
{
    [_cpColor setColor:[WaveHelper intToColor:[controller objectForKey:@"CurrentPositionColor"]]];
    [_traceColor setColor:[WaveHelper intToColor:[controller objectForKey:@"TraceColor"]]];
    [_wpColor setColor:[WaveHelper intToColor:[controller objectForKey:@"WayPointColor"]]];
    [_areaColorGood setColor:[WaveHelper intToColor:[controller objectForKey:@"NetAreaColorGood"]]];
    [_areaColorBad setColor:[WaveHelper intToColor:[controller objectForKey:@"NetAreaColorBad"]]];
    [_areaQual setFloatValue:[[controller objectForKey:@"NetAreaQuality"] floatValue]];
    [_areaSens setIntValue:[[controller objectForKey:@"NetAreaSensitivity"] intValue]];
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

- (BOOL)updateDictionary
{
    [controller setObject:@([_areaQual floatValue]) forKey:@"NetAreaQuality"];
    [controller setObject:@([_areaSens intValue]) forKey:@"NetAreaSensitivity"];
    
    return YES;
}

- (IBAction)setValueForSender:(id)sender
{
    if(sender == _cpColor)
    {
        [controller setObject:[WaveHelper colorToInt:[_cpColor color]] forKey:@"CurrentPositionColor"];
    }
    else if(sender == _traceColor)
    {
        [controller setObject:[WaveHelper colorToInt:[_traceColor color]] forKey:@"TraceColor"];
    }
    else if(sender == _wpColor)
    {
        [controller setObject:[WaveHelper colorToInt:[_wpColor color]] forKey:@"WayPointColor"];
    }
    else if(sender == _areaColorGood)
    {
        [controller setObject:[WaveHelper colorToInt:[sender color]] forKey:@"NetAreaColorGood"];
    }
    else if(sender == _areaColorBad)
    {
        [controller setObject:[WaveHelper colorToInt:[sender color]] forKey:@"NetAreaColorBad"];
    }
    else if(sender == _areaQual)
    {
        [controller setObject:@([sender floatValue]) forKey:@"NetAreaQuality"];
    }
    else if(sender == _areaSens)
    {
        [controller setObject:@([sender intValue]) forKey:@"NetAreaSensitivity"];
    }
    else
    {
        DBNSLog(@"Error: Invalid sender(%@) in setValueForSender:",sender);
    }
}


@end
