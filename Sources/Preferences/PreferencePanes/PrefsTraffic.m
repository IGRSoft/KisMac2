/*
 
 File:			PrefsTraffic.m
 Program:		KisMAC
 Author:		Michael Ro§berg
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

#import "PrefsTraffic.h"
#import "PrefsController.h"

@implementation PrefsTraffic

-(void)updateUI {
    [_showSSID setState:[[controller objectForKey:@"TrafficViewShowSSID"] intValue]];
    [_showBSSID setState:[[controller objectForKey:@"TrafficViewShowBSSID"] intValue]];
    [_avgSignalTime setIntValue:[[controller objectForKey:@"WaveNetAvgTime"] intValue]];
}

-(BOOL)updateDictionary {    
    [_avgSignalTime validateEditing];

    [controller setObject:@([_avgSignalTime intValue]) forKey:@"WaveNetAvgTime"];
    return YES;
}

-(IBAction)setValueForSender:(id)sender {
    if(sender == _showSSID) {
        [controller setObject:[NSNumber numberWithInt:[_showSSID state]] forKey:@"TrafficViewShowSSID"];
    } else if(sender == _showBSSID) {
        [controller setObject:[NSNumber numberWithInt:[_showBSSID state]] forKey:@"TrafficViewShowBSSID"];
    } else if(sender == _avgSignalTime) {
        [controller setObject:@([_avgSignalTime intValue]) forKey:@"WaveNetAvgTime"];
    } else {
        DBNSLog(@"Error: Invalid sender(%@) in setValueForSender:",sender);
    }
}

@end
