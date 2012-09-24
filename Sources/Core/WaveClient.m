/*
        
        File:			WaveClient.m
        Program:		KisMAC
		Author:			Michael Rossberg
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

#import "WaveClient.h"
#import "WaveHelper.h"
#import "WPA.h"
#import "GrowlController.h"

@implementation WaveClient

#pragma mark -
#pragma mark Coder stuff
#pragma mark -

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if ( [coder allowsKeyedCoding] ) {
        _curSignal=[coder decodeIntForKey:@"aCurSignal"];

        _receivedBytes=[coder decodeDoubleForKey:@"aReceivedBytes"];
        _sentBytes=[coder decodeDoubleForKey:@"aSentBytes"];
        
        _ID     = [[coder decodeObjectForKey:@"aID"] retain];
        _date   = [[coder decodeObjectForKey:@"aDate"] retain];
        _IPAddress = [[coder decodeObjectForKey:@"aIPA"] retain];
        
        //WPA stuff
        _sNonce = [[coder decodeObjectForKey:@"sNonce"] retain];
        _aNonce = [[coder decodeObjectForKey:@"aNonce"] retain];
        _packet = [[coder decodeObjectForKey:@"packet"] retain];
        _MIC    = [[coder decodeObjectForKey:@"MIC"] retain];
        _wpaKeyCipher = [coder decodeIntForKey:@"wpaKeyCipher"];
        
        //LEAP stuff
        _leapUsername   = [[coder decodeObjectForKey:@"leapUsername"] retain];
        _leapChallenge  = [[coder decodeObjectForKey:@"leapChallenge"] retain];
        _leapResponse   = [[coder decodeObjectForKey:@"leapResponse"] retain];
        
        _changed = YES;
     } else {
        NSLog(@"Cannot decode this way");
    }
    return self;
}

- (id)initWithDataDictionary:(NSDictionary*)dict {
    self = [self init];
	if (!self) return nil;
	
	_curSignal = [[dict objectForKey:@"curSignal"] intValue];

	_receivedBytes = [[dict objectForKey:@"receivedBytes"] doubleValue];
	_sentBytes = [[dict objectForKey:@"sentBytes"] doubleValue];
	
	_ID     = [[dict objectForKey:@"ID"] retain];
	_date   = [[dict objectForKey:@"date"] retain];
    _IPAddress = [[dict objectForKey:@"IPAddress"] retain];
	
	//WPA stuff
	_sNonce = [[dict objectForKey:@"wpaSNonce"] retain];
	_aNonce = [[dict objectForKey:@"wpaANonce"] retain];
	_packet = [[dict objectForKey:@"wpaPacket"] retain];
	_MIC    = [[dict objectForKey:@"wpaMIC"] retain];
    _wpaKeyCipher = [[dict objectForKey:@"wpaKeyCipher"] intValue];

	//LEAP stuff
	_leapUsername   = [[dict objectForKey:@"leapUsername"] retain];
	_leapChallenge  = [[dict objectForKey:@"leapChallenge"] retain];
	_leapResponse   = [[dict objectForKey:@"leapResponse"] retain];
	
	_changed = YES;

    return self;
}

- (NSDictionary*)dataDictionary {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:[NSNumber numberWithInt:_curSignal] forKey:@"curSignal"];
	[dict setObject:[NSNumber numberWithDouble:_receivedBytes] forKey:@"receivedBytes"];
	[dict setObject:[NSNumber numberWithDouble:_sentBytes] forKey:@"sentBytes"];
	
	[dict setObject:_ID forKey:@"ID"];
	if (_date) [dict setObject:_date forKey:@"date"];
    if (_IPAddress) [dict setObject:_IPAddress forKey:@"IPAddress"];
	
	if (_sNonce) [dict setObject:_sNonce forKey:@"wpaSNonce"];
	if (_aNonce) [dict setObject:_aNonce forKey:@"wpaANonce"];
	if (_packet) [dict setObject:_packet forKey:@"wpaPacket"];
	if (_MIC)    [dict setObject:_MIC forKey:@"wpaMIC"];
    if (_wpaKeyCipher) [dict setObject:[NSNumber numberWithInt:_wpaKeyCipher] forKey:@"wpaKeyCipher"];
        
	if (_leapUsername)  [dict setObject:_leapUsername forKey:@"leapUsername"];
	if (_leapChallenge) [dict setObject:_leapChallenge forKey:@"leapChallenge"];
	if (_leapResponse)  [dict setObject:_leapResponse forKey:@"leapResponse"];

	return dict;
}

#pragma mark -

- (void)wpaHandler:(WavePacket*) w {
    UInt8 nonce[WPA_NONCE_LENGTH];
    NSData *mic, *packet;
    if (![w isEAPPacket])
        return;
    
    if ([w isWPAKeyPacket]) {
        switch ([w wpaCopyNonce:nonce]) {
            case wpaNonceANonce:
                NSLog(@"Detected WPA challenge for %@!", _ID);
				[GrowlController notifyGrowlWPAChallenge:@"" mac:_ID bssid:[w BSSIDString]];
                NSLog(@"Nonce %.2X %.2X", nonce[0], nonce[WPA_NONCE_LENGTH-1]);
                [WaveHelper secureReplace:&_aNonce withObject:[NSData dataWithBytes:nonce length:WPA_NONCE_LENGTH]];
                _wpaKeyCipher = [w wpaKeyCipher];
                break;
            case wpaNonceSNonce:
                NSLog(@"Detected WPA response for %@!", _ID);
				[GrowlController notifyGrowlWPAResponse:@"" mac:_ID bssid:[w BSSIDString]];
                NSLog(@"Nonce %.2X %.2X", nonce[0], nonce[WPA_NONCE_LENGTH-1]);
                [WaveHelper secureReplace:&_sNonce withObject:[NSData dataWithBytes:nonce length:WPA_NONCE_LENGTH]];
                break;
            case wpaNonceNone:
                NSLog(@"Nonce None");
                break;
        }
        packet = [w eapolData];
        mic = [w eapolMIC];
        if (packet) [WaveHelper secureReplace:&_packet withObject:packet];
        if (mic)    [WaveHelper secureReplace:&_MIC    withObject:mic];
    } else if ([w isLEAPKeyPacket]) {
        switch ([w leapCode]) {
        case leapAuthCodeChallenge:
            if (!_leapUsername) [WaveHelper secureReplace:&_leapUsername  withObject:[w username]];
            if (!_leapChallenge) [WaveHelper secureReplace:&_leapChallenge withObject:[w challenge]];
            break;
        case leapAuthCodeResponse:
            if (!_leapResponse) [WaveHelper secureReplace:&_leapResponse  withObject:[w response]];
            break;
        case leapAuthCodeFailure:
            NSLog(@"Detected LEAP authentication failure for client %@! Username: %@. Deleting all collected auth data!", _ID, _leapUsername);
            [WaveHelper secureRelease:&_leapUsername];
            [WaveHelper secureRelease:&_leapChallenge];
            [WaveHelper secureRelease:&_leapResponse];
            break;
        default:
            break;
        }
    }
}

-(void) parseFrameAsIncoming:(WavePacket*)w {
    if (!_ID) {
        _ID=[[w stringReceiverID] retain];
		if ([_ID isEqualToString:@"00:0F:F7:C8:7A:60"] || [_ID isEqualToString:@"00:11:20:EE:CE:48"] || 
			[_ID isEqualToString:@"00:12:D9:B3:16:C0"] || [_ID isEqualToString:@"00:12:D9:B3:18:90"] ||
			[_ID isEqualToString:@"00:12:D9:B3:1D:40"]) {
			NSLog(@"Found desired Access Point: %@", _ID);
			[WaveHelper speakSentence:[[NSString stringWithFormat:@"Found desired Access Point: %@", _ID] UTF8String] withVoice:[[NSUserDefaults standardUserDefaults] integerForKey:@"Voice"]];
			NSBeep(); NSBeep(); NSBeep();
		}
	}

    _receivedBytes+=[w length];
    _changed = YES;
    
    if ([w destinationIPAsString] != nil && ![[w destinationIPAsString] isEqualToString:@"0.0.0.0"] ) {
        _IPAddress = [[w destinationIPAsString] retain];
     //   NSLog(@"Incoming Packet Client dest IP Found: %@", [w destinationIPAsString]);
    }
    
    if (![w toDS])
        [self wpaHandler:w]; //dont store it in the AP client
}

-(void) parseFrameAsOutgoing:(WavePacket*)w {
    if (!_ID) {
        _ID=[[w stringSenderID] retain];
		if ([_ID isEqualToString:@"00:0F:F7:C8:7A:60"] || [_ID isEqualToString:@"00:11:20:EE:CE:48"] || 
			[_ID isEqualToString:@"00:12:D9:B3:16:C0"] || [_ID isEqualToString:@"00:12:D9:B3:18:90"] ||
			[_ID isEqualToString:@"00:12:D9:B3:1D:40"]) {
			NSLog(@"Found desired Access Point: %@", _ID);
			[WaveHelper speakSentence:[[NSString stringWithFormat:@"Found desired Access Point: %@", _ID] UTF8String] withVoice:[[NSUserDefaults standardUserDefaults] integerForKey:@"Voice"]];
			NSBeep(); NSBeep(); NSBeep();
		}
    }
    [WaveHelper secureReplace:&_date withObject:[NSDate date]];
    
    _curSignal=[w signal];
    _sentBytes+=[w length];    
    _changed = YES;
    if ([w sourceIPAsString] != nil  && ![[w sourceIPAsString] isEqualToString:@"0.0.0.0"] ) {
        _IPAddress = [[w sourceIPAsString] retain];
        //NSLog(@"Outgoing Packet Client source IP Found: %@", [w sourceIPAsString]);
    }
    
    if (![w fromDS])
        [self wpaHandler:w]; //dont store it in the AP client
}

#pragma mark -

- (NSString *)ID {
    if (!_ID) return NSLocalizedString(@"<unknown>", "unknown client ID");
    return _ID;
}

- (NSString *)received {
    return [WaveHelper bytesToString: _receivedBytes];
}

- (NSString *)sent {
    return [WaveHelper bytesToString: _sentBytes];
}

- (NSString *)vendor {
    if (_vendor) return _vendor;
    _vendor=[[WaveHelper vendorForMAC:_ID] retain];
    return _vendor;
}

- (NSString *)date {
    if (_date==Nil) return @"";
    else return [NSString stringWithFormat:@"%@", _date]; //return [_date descriptionWithCalendarFormat:@"%H:%M %d-%m-%y" timeZone:nil locale:nil];
}

- (NSString *)getIPAddress{
    if (_IPAddress == Nil) return @"unknown";
    return _IPAddress;
}

#pragma mark -

- (float)receivedBytes {
    return _receivedBytes;
}

- (float)sentBytes {
    return _sentBytes;
}

- (int)curSignal {
    if ([_date compare:[NSDate dateWithTimeIntervalSinceNow:0.5]]==NSOrderedDescending) _curSignal=0;
    return _curSignal;
}

- (NSDate *)rawDate {
    return _date;
}

#pragma mark -
#pragma mark WPA stuff
#pragma mark -

- (NSData *)sNonce {
    return _sNonce;
}

- (NSData *)aNonce {
    return _aNonce;
}

- (NSData *)eapolMIC {
    return _MIC;
}

- (NSData *)eapolPacket {
    return _packet;
}

- (int)wpaKeyCipher {
    return _wpaKeyCipher;
}

- (NSData *)rawID {
    UInt8   ID8[6];
    int     ID32[6];
    int i;
    
    if (!_ID) return Nil;
    
    if (sscanf([_ID UTF8String], "%2X:%2X:%2X:%2X:%2X:%2X", &ID32[0], &ID32[1], &ID32[2], &ID32[3], &ID32[4], &ID32[5]) != 6) return Nil;
    for (i = 0; i < 6; i++)
        ID8[i] = ID32[i];
    
    return [NSData dataWithBytes:ID8 length:6];
}

- (BOOL) eapolDataAvailable {
    if (_sNonce && _aNonce && _MIC && _packet) return YES;
    return NO;
}

#pragma mark -
#pragma mark LEAP stuff
#pragma mark -

- (NSData *)leapChallenge {
    return _leapChallenge;
}
- (NSData *)leapResponse {
    return _leapResponse;
}
- (NSString *)leapUsername {
    return _leapUsername;
}
- (BOOL) leapDataAvailable {
    if (_leapChallenge && _leapResponse && _leapUsername) return YES;
    return NO;
}

#pragma mark -

- (BOOL)changed {
    BOOL c = _changed;
    _changed = NO;
    return c;
}

- (void)wasChanged {
    _changed = YES;
}

#pragma mark -

-(void) dealloc {
    [_date release];
    [_ID release];
    [_vendor release];

    //WPA
    [_sNonce release];
    [_aNonce release];
    [_packet release];
    [_MIC release];
    
    //LEAP
    [_leapUsername  release];
    [_leapChallenge release];
    [_leapResponse  release];
	
	[super dealloc];
}
@end
