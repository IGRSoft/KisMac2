/*
 
 File:			WaveScanner.h
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

#import <pcap.h>

#import "KisMAC80211.h"

@class WaveNet;
@class WaveContainer;
@class WaveClient;
@class ImportController;
@class ScanController;

@interface WaveScanner : NSObject <NSSoundDelegate> 
{    
    NSTimer* _scanTimer;                //timer for refreshing the tables
    NSTimer* _hopTimer;                 //channel hopper

    NSString* _geigerSound;             //sound file for the geiger counter

    NSInteger _packets;                       //packet count
    NSInteger _geigerInt;
    NSInteger _bytes;                         //bytes since last refresh (for graph)
    BOOL _soundBusy;                    //are we clicking?
    
    NSArray *_drivers;                  // Array of drivers
    
    NSInteger _graphLength;
    NSTimeInterval _scanInterval;	//refresh interval
    
    NSInteger  aPacketType;
    BOOL aScanRange;
    BOOL _scanning;
    BOOL _shouldResumeScan;
    BOOL _deauthing;
    double aFreq;
    NSInteger  _driver;
    
    unsigned char aFrameBuf[MAX_FRAME_BYTES];	//for reading in pcaps (still messy)
    KFrame* aWF;
    pcap_t*  _pcapP;

    ImportController *_im;

    IBOutlet ScanController* aController;
    IBOutlet WaveContainer* _container;
   
    NSMutableDictionary *_wavePlugins;
}

- (void)readPCAPDump:(NSString*)dumpFile;
- (KFrame*)nextFrame:(BOOL*)corrupted;

//for communications with ScanController which does all the graphic stuff
- (NSInteger) graphLength;

//scanning properties
- (void) setFrequency:(double)newFreq;
- (BOOL) startScanning;
- (BOOL) stopScanning;
- (BOOL) sleepDrivers: (BOOL)isSleepy;
- (void) setGeigerInterval:(NSInteger)newGeigerInt sound:(NSString *)newSound;
- (NSTimeInterval) scanInterval;

//active attacks
- (NSString *)tryToInject:(WaveNet *)net;
- (void) setDeauthingAll:(BOOL)deauthing;
- (BOOL) authFloodNetwork:(WaveNet *)net;
- (BOOL) deauthenticateNetwork:(WaveNet *)net atInterval:(int)interval;
- (BOOL) beaconFlood;
- (BOOL) stopSendingFrames;
- (BOOL) injectionTest: (WaveNet *)net withClient: (WaveClient *)client;

- (void) sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool;

@end
