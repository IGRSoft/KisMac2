/*
 
 File:			WaveNet.h
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

#import "WavePacket.h"

enum
{
    trafficData,
    packetData,
    signalData
};

enum
{
    chreNone,
    chreChallenge,
    chreResponse,
    chreComplete
};

struct graphStruct
{
    NSInteger trafficData[MAX_YIELD_SIZE + 1];
    NSInteger packetData[MAX_YIELD_SIZE + 1];
    NSInteger signalData[MAX_YIELD_SIZE + 1];
};

@class NetView;
@class WaveWeakContainer;
@class CWNetwork;
@class ImportController;

@interface WaveNet : NSObject /*<UKTest>*/ {
    NSInteger					_netID;					//network ID
    NSInteger					_maxSignal;				//biggest signal ever
    NSInteger					_curSignal;				//current signal
    NSInteger					_channel;				//last channel
    NSInteger					_primaryChannel;        //channel which is broadcasted by AP
    networkType                 _type;                  //0=unknown, 1=ad-hoc, 2=managed, 3=tunnel 4=probe 5=lucent tunnel
    
    // Statistical Data
    NSInteger                   _packets;				//# of packets
    NSInteger					_packetsPerChannel[166];//how many packets on each channel
    NSInteger					_dataPackets;			//# of Data packets
    NSInteger                   _mgmtPackets;           //# of Management packets
    NSInteger                   _ctrlPackets;           //# of Control packets
    
    double                      _bytes;                 //bytes, CGFloat because of size
    NSInteger					graphLength;
    struct graphStruct          *graphData;
    
    encryptionType              _isWep;                 //0=unknown, 1=disabled, 2=enabled 3=40-bit 4-WPA .....
    UInt8                       _IV[3];				    //last iv
    UInt8                       _rawID[6];			    //our id
    UInt8                       _rawBSSID[6];			//our bssid
	UInt8                       _rateCount;
	UInt8                       _rates[MAX_RATE_COUNT];
    BOOL                        _gotData;
    BOOL                        _firstPacket;
    BOOL                        _liveCaptured;
	BOOL                        _graphInit;
	NSDictionary                *_cache;
    BOOL                        _cacheValid;

    NSRecursiveLock *_dataLock;
    
    NetView                 *_netView;
    NSString                *aLat;
    NSString                *aLong;
    NSString                *aElev;
    NSString                *_crackErrorString;

    NSString                *_SSID;
	NSArray                 *_SSIDs;
    NSString                *_BSSID;
    NSString                *_IPAddress;
    NSString                *_vendor;
    NSString                *_password;
    NSString                *aComment;
    NSString                *_ID;
    NSDate                  *_date;		//current date
    NSDate                  *aFirstDate;
    NSMutableArray          *_packetsLog;    //array with a couple of packets to calculate checksum
    NSMutableArray          *_ARPLog;        //array with a couple of packets to do reinjection attack
    NSMutableArray          *_ACKLog;        //array with a couple of packets to do reinjection attack
    NSMutableDictionary     *aClients;
    NSMutableArray          *aClientKeys;
    NSMutableDictionary     *_coordinates;
    WaveWeakContainer       *_ivData[4];       //one for each key id
    
    NSInteger               _challengeResponseStatus;
    
    NSColor                 *_graphColor;	// display color in TrafficView
    NSInteger               recentTraffic;
    NSInteger               recentPackets;
    NSInteger               recentSignal;
    NSInteger               curPackets;		// for setting graphData
    NSInteger               curTraffic;		// for setting graphData
    NSInteger               curTrafficData;		// for setting graphData
    NSInteger               curPacketData;		// for setting graphData
    NSInteger               curSignalData;		// for setting graphData
    NSInteger               _avgTime;               // how many seconds are take for average?
    ImportController        *_im;

/*	PRGA Snarf */
	NSInteger _authState;
		
}

- (id)initWithID:(NSInteger)netID;
- (id)initWithNetstumbler:(const char *)buf andDate:(NSString *)date;
- (id)initWithDataDictionary:(NSDictionary*)dict;
- (void)mergeWithNet:(WaveNet *)net;

- (void)updateSettings:(NSNotification *)note;

- (BOOL)noteFinishedSweep:(NSInteger)num;
- (NSColor *)graphColor;
- (void)setGraphColor:(NSColor *)newColor;
- (NSComparisonResult)compareSignalTo:(id)net;
- (NSComparisonResult)comparePacketsTo:(id)net;
- (NSComparisonResult)compareTrafficTo:(id)net;
- (NSComparisonResult)compareRecentTrafficTo:(id)aNet;

- (NSDictionary*)dataDictionary;

- (struct graphStruct)graphData;
- (NSDictionary *)getClients;
- (NSArray *)getClientKeys;
- (void)setVisible:(BOOL)visible;

- (encryptionType)wep;
- (NSString *)ID;
- (NSString *)BSSID;
- (NSString *)SSID;
- (BOOL)isCorrectSSID;
- (NSArray *)SSIDs;
- (NSString *)rawSSID;
- (NSString *)date;
- (NSDate*)lastSeenDate;
- (NSString *)firstDate;
- (NSDate *)firstSeenDate;
- (NSString *)getIP;
- (NSString *)data;
- (NSString *)getVendor;
- (NSString *)rates;
- (NSArray *)cryptedPacketsLog;      //a couple of encrypted packets
- (NSMutableArray *)arpPacketsLog;	//a couple of reinject packets
- (NSMutableArray *)ackPacketsLog;	//a couple of reinject packets
- (NSString *)key;
- (NSString *)lastIV;
- (NSString *)comment;
- (void)setComment:(NSString *)comment;
- (NSDictionary*)coordinates;
- (WaveWeakContainer *__strong *)ivData;
- (BOOL)passwordAvailable;
- (NSInteger)challengeResponseStatus;

- (NSDictionary *)cache;

- (NSString *)latitude;
- (NSString *)longitude;
- (NSString *)elevation;

- (double)dataCount;
- (NSInteger)curTraffic;
- (NSInteger)curPackets;
- (NSInteger)curSignal;
- (NSInteger)maxSignal;
- (NSInteger)avgSignal;
- (NSInteger)channel;
- (NSInteger)originalChannel;
- (networkType)type;

// Packet Statistics
- (NSInteger)packets;
- (NSInteger)uniqueIVs;
- (NSInteger)dataPackets;
- (NSInteger)mgmtPackets;
- (NSInteger)ctrlPackets;

- (NSInteger*)packetsPerChannel;
- (void)setNetID:(NSInteger)netID;
- (NSInteger)netID;
- (UInt8 *)rawBSSID;
- (UInt8 *)rawID;
- (BOOL)liveCaptured;

- (BOOL)joinNetwork;

- (void)parsePacket:(WavePacket*)w withSound:(BOOL)sound;
- (void)parseAppleAPIData:(CWNetwork *)info;

- (void)sortByColumn:(NSString *)ident order:(BOOL)ascend;

- (NSInteger)capturedEAPOLKeys;
- (NSInteger)capturedLEAPKeys;

- (NSString*)crackError;
- (NSString*)asciiKey;

@end
