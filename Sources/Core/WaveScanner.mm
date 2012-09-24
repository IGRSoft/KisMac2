/*
        
        File:			WaveScanner.mm
        Program:		KisMAC
		Author:			Michael Ro§berg
						mick@binaervarianz.de
		Description:	KisMAC is a wireless stumbler for MacOS X.
                
        This file is part of KisMAC.

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
#import "WaveScanner.h"
#import "ScanController.h"
#import "ScanControllerScriptable.h"
#import "WaveHelper.h"
#import "WaveDriver.h"
#import "KisMACNotifications.h"
#import "80211b.h"
#import "KisMAC80211.h"
#include <unistd.h>
#include <stdlib.h>

@implementation WaveScanner

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _scanning=NO;
    _driver = 0;
    
    srandom(55445);	//does not have to be to really random
    
    _scanInterval = 0.25;
    _graphLength = 0;
    _soundBusy = NO;
    
    _waveSpectrum = [[WaveSpectrumDriver alloc] init];
    return self;
}

#pragma mark -

- (WaveDriver*) getInjectionDriver {
    unsigned int i;
    NSArray *a;
    WaveDriver *w = Nil;
    
    a = [WaveHelper getWaveDrivers];
    for (i = 0; i < [a count]; i++) {
        w = [a objectAtIndex:i];
        if ([w allowsInjection]) break;
    }
    
    if (![w allowsInjection]) {
        NSRunAlertPanel(NSLocalizedString(@"Invalid Injection Option.", "No injection driver title"),
            NSLocalizedString(@"Invalid Injection Option description", "LONG description of the error"),
            //@"None of the drivers selected are able to send raw frames. Currently only PrismII based device are able to perform this task."
            OK, Nil, Nil);
        return Nil;
    }
    
    return w;
}
#define mToS(m) [NSString stringWithFormat:@"%.2X:%.2X:%.2X:%.2X:%.2X:%.2X", m[0], m[1], m[2], m[3], m[4], m[5], m[6]]

#pragma mark -
-(void)performScan:(NSTimer*)timer {
    [_container scanUpdate:_graphLength];
    
    if(_graphLength < MAX_YIELD_SIZE)
        _graphLength++;

    [aController updateNetworkTable:self complete:NO];
    
    [_container ackChanges];
}


//does the active scanning (extra thread)
- (void)doActiveScan:(WaveDriver*)wd {
    NSArray *nets;
    CWNetwork *network;
    unsigned int i;
    float interval;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    interval = [defs floatForKey:@"activeScanInterval"];
    if ([wd startedScanning]) {
		while (_scanning) {
			nets = [wd networksInRange];
			
			if (nets) {
				for(i=0; i<[nets count]; i++) {
					network = [nets objectAtIndex:i];                
					[_container addAppleAPIData:network];
				}
			}
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
		}
	}
}

//does the actual scanning (extra thread)
- (void)doPassiveScan:(WaveDriver*)wd {
    WavePacket *w = Nil;
    KFrame* frame = NULL;

    int dumpFilter;

    NSSound* geiger;
    NSAutoreleasePool *pool;
    
    BOOL error = FALSE;

    NSDictionary *d;
    
    id _wavePlugin;
    WavePcapDump *_wavePcapDumper = nil;
    WavePluginPacketResponse response;
    
    d = [wd configuration];
    dumpFilter = [[d objectForKey:@"dumpFilter"] intValue];
    
    // Initialize WavePlugins
    _wavePlugins = [[NSMutableDictionary alloc] init];
    
    _wavePlugin = [[WavePluginInjectionProbe alloc] initWithDriver:wd];
    [_wavePlugins setValue:_wavePlugin forKey:@"InjectionProbe"];
    [_wavePlugin release];

    _wavePlugin = [[WavePluginDeauthentication alloc] initWithDriver:wd andContainer:_container];
    [_wavePlugins setValue:_wavePlugin forKey:@"Deauthentication"];
    [_wavePlugin release];
 
    _wavePlugin = [[WavePluginInjecting alloc] initWithDriver:wd];
    [_wavePlugins setValue:_wavePlugin forKey:@"Injecting"];
    [_wavePlugin release];
    
    _wavePlugin = [[WavePluginAuthenticationFlood alloc] initWithDriver:wd];
    [_wavePlugins setValue:_wavePlugin forKey:@"AuthenticationFlood"];
    [_wavePlugin release];
    
    _wavePlugin = [[WavePluginBeaconFlood alloc] initWithDriver:wd];
    [_wavePlugins setValue:_wavePlugin  forKey:@"BeaconFlood"];
    [_wavePlugin release];
    
    _wavePlugin = [[WavePluginMidi alloc] initWithDriver: wd];
    [_wavePlugins setValue:_wavePlugin  forKey:@"MidiTrack"];
    [_wavePlugin release];
    
    //tries to open the dump file
    if (dumpFilter) {
        _wavePcapDumper = [[WavePcapDump alloc] initWithDriver:wd andDumpFilter:dumpFilter];
        if (_wavePcapDumper == nil) {
            error = TRUE;
        } else {
            [_wavePlugins setValue:_wavePcapDumper  forKey:@"PacketDump"];
        }
        [_wavePcapDumper release];
    }
    
    if(!error)
    {
        w = [[WavePacket alloc] init];
        pool = [NSAutoreleasePool new];
        
        if (_geigerSound!=Nil)
        {
            geiger=[NSSound soundNamed:_geigerSound];
            if (geiger!=Nil) [geiger setDelegate:self];
        } else geiger=Nil;
        
        if (![wd startedScanning])
        {
            error = TRUE;
        }
        
        while (_scanning && !error) //this is for canceling
        {				
            @try
            {
                frame = [wd nextFrame];     // captures the next frame (locking)
                if (frame == NULL)          // NULL Pointer? 
                    break;
                
                if ([w parseFrame:frame] != NO) //parse packet (no if unknown type)
                {
                    // Send packet to ALL plugins
                    NSEnumerator *plugins = [_wavePlugins objectEnumerator];
                    response = WavePluginPacketResponseContinue;
                    while ((_wavePlugin = [plugins nextObject]) && (response & WavePluginPacketResponseContinue)) {
                        response = [_wavePlugin gotPacket:w fromDriver:wd];
                        // Checks if packet should be forwarded to other plugins
                    }
                    if (!(response & WavePluginPacketResponseContinue))
                        continue;
                    
                    if ([_container addPacket:w liveCapture:YES] == NO)			// the packet shall be dropped
                    {	
                        continue;
                    }

                                        
                    if ((geiger!=Nil) && ((_packets % _geigerInt)==0)) 
                    {
                        if (_soundBusy) 
                        {
                            _geigerInt+=10;
                        }
                        else
                        {
                            _soundBusy=YES;
                            [geiger play];
                        }
                    }
                    
                    _packets++;
                    
                    if (_packets % 10000 == 0) 
                    {
                        [pool release];
                        pool = [NSAutoreleasePool new];
                    }
                    
                    _bytes+=[w length];
                }//end parse frame
                else {
					if (_wavePcapDumper) {
						[_wavePcapDumper gotPacket:w fromDriver:wd];
					}
                    NSLog(@"WaveScanner: Unknown packet type in parseFrame");   
                }
            }
            @finally 
            {
            }
        }

        //these are only allocated if there is no error
        
        [w release];
        [pool release];
    }   // no error
    
    [_wavePlugins release];
    _wavePlugins = nil;
    _wavePcapDumper = nil;
    
}

- (void)doScan:(WaveDriver*)w {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSThread setThreadPriority:1.0];	//we are important
    
    if ([w type] == passiveDriver) { //for PseudoJack this is done by the timer
        [self doPassiveScan:w];
    } else if ([w type] == activeDriver) {
        [self doActiveScan:w];
    }

    [w stopCapture];
    [self stopScanning];					//just to make sure the user can start the thread if it crashed
    [pool release];
}

- (bool)startScanning {
    WaveDriver *w;
    NSArray *a;
    unsigned int i;
    
    if (!_scanning) {			//we are already scanning
        _scanning=YES;
        a = [WaveHelper getWaveDrivers];
        [WaveHelper secureReplace:&_drivers withObject:a];

        for (i = 0; i < [_drivers count]; i++)
        {
            w = [_drivers objectAtIndex:i];
            if ([w type] == passiveDriver) 
            { //for PseudoJack this is done by the timer
                [w startCapture:0];
            }
            
            [NSThread detachNewThreadSelector:@selector(doScan:) toTarget:self withObject:w];
        }
        
        _scanTimer = [NSTimer scheduledTimerWithTimeInterval:_scanInterval target:self selector:@selector(performScan:) userInfo:Nil repeats:TRUE];
        if (_hopTimer == Nil)
            _hopTimer=[NSTimer scheduledTimerWithTimeInterval:aFreq target:self selector:@selector(doChannelHop:) userInfo:Nil repeats:TRUE];
    }
    
    return YES;
}

- (bool)stopScanning {
    if (_scanning) {
		[GrowlController notifyGrowlStopScan];
        _scanning=NO;
        [_scanTimer invalidate];
        _scanTimer = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:KisMACStopScanForced object:self];

        if (_hopTimer!=Nil) {
            [_hopTimer invalidate];
            _hopTimer=Nil;
        }
		
    }
    return YES;
}

- (bool)sleepDrivers: (bool)isSleepy{
    WaveDriver *w;
    NSArray *a;
    unsigned int i;
    
    a = [WaveHelper getWaveDrivers];
    [WaveHelper secureReplace:&_drivers withObject:a];
        
   if (isSleepy) {
		NSLog(@"Going to sleep...");
        _shouldResumeScan = _scanning;
        [aController stopScan];
		for (i = 0; i < [_drivers count]; i++) {
			w = [_drivers objectAtIndex:i];
            [w sleepDriver];
        }
    } else {
		NSLog(@"Waking up...");
		for (i = 0; i < [_drivers count]; i++) {
			w = [_drivers objectAtIndex:i];
            [w wakeDriver];
		}
        if (_shouldResumeScan) {
            [aController startScan];
        }
    }

    return YES;
}

- (void)doChannelHop:(NSTimer*)timer {
    unsigned int i;
    
    for (i = 0; i < [_drivers count]; i++) {
        [[_drivers objectAtIndex:i] hopToNextChannel];
    }
}

-(void)setFrequency:(double)newFreq {
    aFreq=newFreq;
    if (_hopTimer!=Nil) {
        [_hopTimer invalidate];
        _hopTimer=[NSTimer scheduledTimerWithTimeInterval:aFreq target:self selector:@selector(doChannelHop:) userInfo:Nil repeats:TRUE];
    }
   
}
-(void)setGeigerInterval:(int)newGeigerInt sound:(NSString*) newSound {
    
    [WaveHelper secureRelease:&_geigerSound];
    
    if ((newSound==Nil)||(newGeigerInt==0)) return;
    
    _geigerSound=[newSound retain];
    _geigerInt=newGeigerInt;
}

#pragma mark -

- (NSTimeInterval)scanInterval {
    return _scanInterval;
}
- (int)graphLength {
    return _graphLength;
}

//reads in a pcap file
-(void)readPCAPDump:(NSString*) dumpFile
{
    char err[PCAP_ERRBUF_SIZE];
    WavePacket *w;
    KFrame* frame=NULL;
    bool corrupted;
    
    #ifdef DUMP_DUMPS
        pcap_dumper_t* f=NULL;
        pcap_t* p=NULL;
        NSString *aPath;
        
        if (aDumpLevel)
        {
            //in the example dump are informations like 802.11 network
            aPath=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/example.dump"];
            p=pcap_open_offline([aPath UTF8String],err);
            if (p==NULL)
                return;
            //opens output
            aPath=[[NSDate date] descriptionWithCalendarFormat:[aDumpFile stringByExpandingTildeInPath] 
                                                      timeZone:nil locale:nil];
            f=pcap_dump_open(p,[aPath UTF8String]);
            if (f==NULL) 
                return;
        }
    #endif
    
    _pcapP=pcap_open_offline([dumpFile UTF8String],err);
    if (_pcapP == NULL) 
    {
        NSLog(@"Could not open dump file: %@. Reason: %s", dumpFile, err);
        return;
    }

    memset(aFrameBuf, 0, sizeof(aFrameBuf));
    aWF=(KFrame*)aFrameBuf;
    
    w=[[WavePacket alloc] init];

    while (true) 
    {
        frame = [self nextFrame:&corrupted];
        if (frame == NULL) 
        {
            if (corrupted) continue;
            else break;
        }
                
        if ([w parseFrame:frame] != NO) 
        {

            if ([_container addPacket:w liveCapture:NO] == NO)
                continue; // the packet shall be dropped
            
            #ifdef DUMP_DUMPS
                if ((aDumpLevel==1) || 
                    ((aDumpLevel==2)&&([w type]==IEEE80211_TYPE_DATA)) || 
                    ((aDumpLevel==3)&&([w isResolved]!=-1))) [w dump:f]; //dump if needed
            #endif
        }
    }//while

    #ifdef DUMP_DUMPS
        if (f) pcap_dump_close(f);
        if (p) pcap_close(p);
    #endif

    [w release];
    pcap_close(_pcapP);
}

//returns the next frame in a pcap file
-(KFrame*) nextFrame:(bool*)corrupted
{
    UInt8 *b;
    struct pcap_pkthdr h;
    int offset;

    *corrupted = NO;
    
    b=(UInt8*)pcap_next(_pcapP,&h);	//get frame from current pcap file

    if(b == NULL) return NULL;

    *corrupted = YES;
    
    aWF->ctrl.channel = 0;
    aWF->ctrl.len = h.caplen;
    
    //corrupted frame
    if ( h.caplen > 2364 ) return NULL;
    
    switch (pcap_datalink(_pcapP))
    {
        case DLT_IEEE802_11:
            offset = 0;
        break;
            
        case DLT_PRISM_HEADER:
            offset = sizeof(prism_header);
        break;
            
        case DLT_IEEE802_11_RADIO:
            offset = ((ieee80211_radiotap_header*)b)->it_len;
        break;
            
        default:
            NSLog(@"Unsupported Datalink Type: %u.", pcap_datalink(_pcapP));
            pcap_close(_pcapP);
            return NULL;
        break;
    }

    memcpy(aWF->data, b+offset, h.caplen);
    return aWF;   
}

#pragma mark -

- (void) setDeauthingAll:(BOOL)deauthing {
    WavePluginDeauthentication *wavePlugin;
    wavePlugin = [_wavePlugins valueForKey:@"Deauthentication"];
    if (wavePlugin == nil)
        return;
    [wavePlugin setDeauthingAll:deauthing];
    return;
}
- (bool) beaconFlood {
    WavePluginBeaconFlood *wavePlugin;
    bool ret;
    wavePlugin = [_wavePlugins valueForKey:@"BeaconFlood"];
    if (wavePlugin == nil)
        return NO;
    ret = [wavePlugin startTest];
    return ret;
}
- (bool) deauthenticateNetwork:(WaveNet*)net atInterval:(int)interval {
    WavePluginDeauthentication *wavePlugin;
    bool ret;
    wavePlugin = [_wavePlugins valueForKey:@"Deauthentication"];
    if (wavePlugin == nil)
        return NO;
    ret = [wavePlugin startTest:net atInterval:interval];
    return ret;
}
- (NSString*) tryToInject:(WaveNet*)net {
    bool ret;
    WavePluginInjecting *wavePlugin;
    
    wavePlugin = [_wavePlugins valueForKey:@"Injecting"];
    if (wavePlugin == nil)
        return NO;
    ret = [wavePlugin startTest:net];
    if (ret == NO) {
        return nil;
    } else {
        return @"";
    }
    return NO;    
}
- (bool) injectionTest: (WaveNet *)net withClient:(WaveClient *)client
{
    WavePluginInjectionProbe *wavePlugin;
    wavePlugin = [_wavePlugins valueForKey:@"InjectionProbe"];
    if (wavePlugin == nil)
        return NO;
    [wavePlugin startTest:net withClient:client];
    return YES;
}
- (bool) authFloodNetwork:(WaveNet*)net {
    WavePluginAuthenticationFlood *wavePlugin;
    
    wavePlugin = [_wavePlugins valueForKey:@"AuthenticationFlood"];
    if (wavePlugin == nil)
        return NO;
    return [wavePlugin startTest:net];
}

- (bool) stopSendingFrames {
    WaveDriver *w;
    NSArray *a;
    unsigned int i;
    id test;
    
    // Stop all tests
    NSEnumerator *tests = [_wavePlugins objectEnumerator];
    while ((test = [tests nextObject])) {
        [test stopTest];
    }
    
    // Stop all drivers
    a = [WaveHelper getWaveDrivers];
    for (i = 0; i < [a count]; i++) {
        w = [a objectAtIndex:i];
        if ([w allowsInjection]) [w stopSendingFrames];
    }
    
    return YES;
}

#pragma mark -

- (void)sound:(NSSound *)sound didFinishPlaying:(bool)aBool {
    _soundBusy=NO;
}

- (void)dealloc {
    [self stopSendingFrames];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _scanning=NO;
    [super dealloc];
}

@end
