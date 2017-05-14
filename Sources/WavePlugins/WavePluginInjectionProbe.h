/*
 
 File:			WavePluginInjectionProbe.h
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

@class WaveClient;

@interface WavePluginInjectionProbe : WavePlugin 
{
    IBOutlet NSWindow *probeSheet;
    
    IBOutlet NSImageView *statusRate1;
    IBOutlet NSImageView *statusRate2;
    IBOutlet NSImageView *statusRate5_5;
    IBOutlet NSImageView *statusRate11;
    IBOutlet NSImageView *statusRate6;
    IBOutlet NSImageView *statusRate9;
    IBOutlet NSImageView *statusRate12;
    IBOutlet NSImageView *statusRate18;
    IBOutlet NSImageView *statusRate24;
    IBOutlet NSImageView *statusRate36;
    IBOutlet NSImageView *statusRate48;
    IBOutlet NSImageView *statusRate54;
    
    IBOutlet NSButton *button;
    IBOutlet NSTextField *textFieldAP;
    
	WaveClient *_clientInTest;
	
    NSImage *statusOK;
    NSImage *statusNOK;
    NSImage *statusSPIN;
    
    NSEnumerator	*_currentRateEnumerator;
    NSNumber		*_currentRate;
    NSTimer			*_timer;
    BOOL			_catchedPacket;
    
    UInt8 _randomSourceMAC[6];
    UInt8 _checks;

}

- (BOOL) startTest: (WaveNet *)net withClient:(WaveClient *)client;
- (void) stepTestProbeRequest;
- (void) stepTestRTS;
- (void) checkResponse;
- (IBAction) endProbeSheet: (id) sender;
- (id) imageCellForRate: (NSNumber*) rate;

@end
