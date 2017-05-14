/*
 
 File:			WavePacket.h
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

#import "KisMAC80211.h"
#import <sys/time.h>

//#define DEBUG			//This has currently no meaning
//#define LOGPACKETS		//do not enable unless you know what you are doing

#define MAX_RATE_COUNT 64

//this is given to us by the driver
struct sAirportFrame { // 14 Byte
    UInt16 status;
    UInt16 reserved0;
    UInt16 reserved1;
    UInt8  signal;
    UInt8  silence;
    UInt16 rate;
    UInt16 reserved2;
    UInt16 txControl;
};

//the beginning of each beacon frame. currently not in use
struct sBeaconFrame { //at least 12 bytes
    UInt8  timestamp[8];
    UInt16 beaconInterval;
    UInt16 capabilities;
};

typedef NS_ENUM(NSUInteger, networkType)
{
    networkTypeUnknown      = 0,
    networkTypeAdHoc        = 1,
    networkTypeManaged      = 2,
    networkTypeTunnel       = 3,
    networkTypeProbe        = 4,
    networkTypeLucentTunnel = 5
};

typedef NS_ENUM(NSUInteger, wpaNoncePresent)
{
    wpaNonceNone = 0,
    wpaNonceANonce,
    wpaNonceSNonce
};

typedef NS_ENUM(NSUInteger, encryptionType)
{
    encryptionTypeUnknown   = 0,
    encryptionTypeNone      = 1,
    encryptionTypeWEP       = 2,
    encryptionTypeWEP40     = 3,
    encryptionTypeWPA       = 4,
    encryptionTypeLEAP      = 5,
    encryptionTypeWPA2      = 6,    
};

typedef NS_ENUM(NSUInteger, leapAuthCode)
{
    leapAuthCodeChallenge   = 1,
    leapAuthCodeResponse    = 2,
    leapAuthCodeSuccess     = 3,
    leapAuthCodeFailure     = 4    
};

//this represents a packet
@interface WavePacket : NSObject /*<UKTest>*/ {
    NSInteger _signal;            // current signal strength
    NSInteger _channel;           // well the channel
    NSInteger  _primaryChannel;   // Primary channel
    NSInteger _type;			//type 0=management 1=control 2=data
    NSInteger _subtype;		//deprending on type, WARNING might be little endian
    
    networkType    _netType;    //0=unknown, 1=ad-hoc, 2=managed, 3=tunnel
    encryptionType _isWep;      //0=unknown, 1=disabled, 2=enabled
    leapAuthCode   _leapCode;
    
    BOOL _isToDS;		//to access point?
    BOOL _isFrDS;		//from access point?
    BOOL _isEAP;

    NSString		*_SSID;
    NSMutableArray	*_SSIDs;
	
	UInt8			_rateCount;
	UInt8			_rates[MAX_RATE_COUNT];
	
	NSString *_username;
    NSData   *_challenge;
    NSData   *_response;
    
    struct timeval _creationTime; //time for cap
    
    UInt8* _frame;                  // 80211 frame
    UInt8 *_payload;                // Payload

    NSInteger _length;                    // Length of 80211 frame
    NSInteger _headerLength;              // Length of 80211 header
    NSInteger _payloadLength;				// Length of payload

    NSInteger _revelsKeyByte;         //-2 = no idea

    UInt8 _addr1[ETH_ALEN];
    UInt8 _addr2[ETH_ALEN];
    UInt8 _addr3[ETH_ALEN];
    UInt8 _addr4[ETH_ALEN];
    
    //WPA stuff
    NSInteger _wpaKeyCipher;
    wpaNoncePresent _nonce;
}

//input function
- (BOOL)parseFrame:(KFrame*) f;

- (NSInteger)length;          // Length of 80211 frame
- (NSInteger)payloadLength;   // Length of payload
- (NSInteger)signal;
- (NSInteger)channel;
- (NSInteger)type;
- (NSInteger)subType;
- (NSInteger)primaryChannel;
- (BOOL)fromDS;
- (BOOL)toDS;
- (encryptionType)wep;
- (networkType)netType;
- (UInt8*)payload;      // payload
- (UInt8*)frame;
- (NSInteger)isResolved;	//for wep cracking 
- (NSString*)SSID;
- (NSArray*)SSIDs;
- (UInt8)getRates:(UInt8*)rates;
- (BOOL)isCorrectSSID;

- (UInt8*)rawSenderID;
- (NSString*)stringSenderID;
- (UInt8*)rawReceiverID;
- (NSString*)stringReceiverID;
- (UInt8*)rawBSSID;
- (NSString*)BSSIDString;
- (BOOL)BSSID:(UInt8*)bssid;
- (BOOL)ID:(UInt8*)ident;
- (NSString*)IDString;	//gives a unique for each net, bssid is not useful
- (BOOL)isEAPPacket;
- (struct timeval *)creationTime;

// IP handling by Dylan Neild
- (NSString *)sourceIPAsString;
- (NSString *)destinationIPAsString;
- (unsigned char *)sourceIPAsData;
- (unsigned char *)destinationIPAsData;

// MAC Addresses
- (UInt8*)addr1;
- (UInt8*)addr2;
- (UInt8*)addr3;
- (UInt8*)addr4;

//WPA handling
- (BOOL)isWPAKeyPacket;
- (wpaNoncePresent)wpaCopyNonce:(UInt8*)destNonce;
- (NSInteger)wpaKeyCipher;
- (NSData*)eapolMIC;
- (NSData*)eapolData;

//LEAP handling
- (BOOL)isLEAPKeyPacket;
- (leapAuthCode)leapCode;
- (NSString*)username;
- (NSData*)challenge;
- (NSData*)response;
@end
