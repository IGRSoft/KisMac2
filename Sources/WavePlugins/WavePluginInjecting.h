/*
 
 File:			WavePluginInjecting.m
 Program:		KisMAC
 Author:		pr0gg3d
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

#import "WavePlugin.h"
#import "KisMAC80211.h"

@interface WavePluginInjecting : WavePlugin {
    int  _injReplies;
    
	UInt8 _addr1[ETH_ALEN];
    UInt8 _addr2[ETH_ALEN];
    UInt8 _addr3[ETH_ALEN];
	
    int			aPacketType;
    NSTimer		*_timer;
    KFrame		_kframe;
    BOOL	_checkInjectedPackets;
    
    IBOutlet NSWindow *probeSheet;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSTextField *ssid;
    IBOutlet NSTextField *operation;
    IBOutlet NSTextField *responses;
    IBOutlet NSProgressIndicator *progIndicator;
}

- (BOOL) startTest: (WaveNet *)net;
- (void) stepPerformInjection:(NSTimer *)timer;
- (void) stepCheckInjected;
- (void) checkStopInjecting: (NSTimer *)timer;
- (IBAction) endProbeSheet: (id) sender;

@end
