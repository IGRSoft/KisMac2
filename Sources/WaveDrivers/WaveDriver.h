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
    UInt16 _firstChannel;
    UInt16 _currentChannel;
    UInt16 _lastChannel;
    NSArray *_useChannel;
    NSUInteger _autoRepeat;
    NSUInteger _packets;
    NSUInteger _hopFailure;
    NSUInteger _allowedChannels;
    KMRate _currentRate;
	
    BOOL _autoAdjustTimer;
    BOOL _hop;
    BOOL _etsi;
    BOOL _fcc;
    
    NSArray *_permittedRates;
}

+ (enum WaveDriverType) type;
+ (BOOL) allowsInjection;
+ (BOOL) wantsIPAndPort;
+ (BOOL) allowsChannelHopping;
+ (BOOL) allowsMultipleInstances;
+ (NSString*) description;
+ (NSString*) deviceName;

+ (BOOL) loadBackend;
+ (BOOL) unloadBackend;

- (enum WaveDriverType) type;
- (BOOL) allowsInjection;
- (BOOL) wantsIPAndPort;
- (BOOL) allowsChannelHopping;
- (BOOL) allowsMultipleInstances;
- (BOOL) unloadBackend;
- (NSString*) deviceName;

- (NSComparisonResult)compareDrivers:(WaveDriver *)driver;

- (BOOL)setConfiguration:(NSDictionary*)dict;
- (NSDictionary*)configuration;
- (BOOL)ETSI;
- (BOOL)FCC;
- (BOOL)hopping;
- (BOOL)autoAdjustTimer;
- (void)hopToNextChannel;

- (UInt16) getChannel;
- (BOOL) setChannel:  (UInt16)newChannel;
- (BOOL) startCapture:(UInt16)newChannel;
- (BOOL) stopCapture;
- (BOOL) sleepDriver;
- (BOOL) wakeDriver;

// for active scanning
- (NSArray*) networksInRange;

// for passive scanning
- (KFrame*) nextFrame;

// for the kismet drones
-(BOOL) startedScanning;
-(BOOL) stoppedScanning;

// for packet injection
-(BOOL) sendKFrame:(KFrame *)f howMany:(NSInteger)howMany atInterval:(NSInteger)interval;
-(BOOL) sendKFrame:(KFrame *)f howMany:(NSInteger)howMany atInterval:(NSInteger)interval notifyTarget:(id)target notifySelectorString:(NSString *)selector;
-(BOOL) stopSendingFrames;

//for the cards that support this
- (UInt16) allowedChannels;
- (KMRate) currentRate;
- (BOOL) setCurrentRate: (KMRate)rate;

//For injection and other things
- (NSArray *) permittedRates;

@end
