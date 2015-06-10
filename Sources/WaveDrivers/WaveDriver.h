/*
 
 File:			WaveDriver.h
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

#import "../Core/KisMAC80211.h"
#import "../Core/KMCommon.h"

extern char WaveDrivers [][30];

enum WaveDriverType
{
    activeDriver,
    passiveDriver,
    notSpecifiedDriver
};

@interface WaveDriver : NSObject
{
    NSDictionary *_config;
    int _firstChannel;
    int _currentChannel;
    int _useChannel[14];
    int _autoRepeat;
    int _packets;
    int _lastChannel;
    int _hopFailure;
    int _allowedChannels;
    KMRate _currentRate;
	
    bool _autoAdjustTimer;
    bool _hop;
    bool _etsi;
    bool _fcc;
    
    NSArray *_permittedRates;
}

+ (enum WaveDriverType) type;
+ (bool) allowsInjection;
+ (bool) wantsIPAndPort;
+ (bool) allowsChannelHopping;
+ (bool) allowsMultipleInstances;
+ (NSString*) description;
+ (NSString*) deviceName;

+ (bool) loadBackend;
+ (bool) unloadBackend;

- (enum WaveDriverType) type;
- (bool) allowsInjection;
- (bool) wantsIPAndPort;
- (bool) allowsChannelHopping;
- (bool) allowsMultipleInstances;
- (bool) unloadBackend;
- (NSString*) deviceName;

- (NSComparisonResult)compareDrivers:(WaveDriver *)driver;

- (bool)setConfiguration:(NSDictionary*)dict;
- (NSDictionary*)configuration;
- (bool)ETSI;
- (bool)FCC;
- (bool)hopping;
- (bool)autoAdjustTimer;
- (void)hopToNextChannel;

- (unsigned short) getChannel;
- (bool) setChannel:  (unsigned short)newChannel;
- (bool) startCapture:(unsigned short)newChannel;
- (bool) stopCapture;
- (bool) sleepDriver;
- (bool) wakeDriver;

// for active scanning
- (NSArray*) networksInRange;

// for passive scanning
- (KFrame*) nextFrame;

// for the kismet drones
-(bool) startedScanning;
-(bool) stoppedScanning;

// for packet injection
-(bool) sendKFrame:(KFrame *)f howMany:(int)howMany atInterval:(int)interval;
-(bool) sendKFrame:(KFrame *)f howMany:(int)howMany atInterval:(int)interval notifyTarget:(id)target notifySelectorString:(NSString *)selector;
-(bool) stopSendingFrames;

//for the cards that support this
- (int) allowedChannels;
- (KMRate) currentRate;
- (bool) setCurrentRate: (KMRate)rate;

//For injection and other things
- (NSArray *) permittedRates;

@end
