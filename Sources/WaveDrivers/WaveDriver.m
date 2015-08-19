/*
 
 File:			WaveDriver.m
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

#import "WaveDriverAirport.h"
#import "WaveHelper.h"

char WaveDrivers [][30] =
{
    "WaveDriverAirport",
    "WaveDriverKismet",
	"WaveDriverKismetDrone",
    "WaveDriverAirportExtreme",
    "WaveDriverUSBIntersil",
    "WaveDriverUSBRalinkRT73",
    "WaveDriverUSBRalinkRT2570",
    "WaveDriverUSBRealtekRTL8187",
    "\0"
};

@implementation WaveDriver

- (id) init {
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    _permittedRates = nil;
	_currentRate = KMRate11;
    
    return self;
}
//private
- (NSInteger) getChannelUnCached
{
    return 0;
}

#pragma mark -

+ (enum WaveDriverType) type
{
    return notSpecifiedDriver;
}

+ (BOOL) allowsInjection
{
    return NO;
}

+ (BOOL) wantsIPAndPort
{
    return NO;
}

+ (BOOL) allowsChannelHopping
{
    return NO;
}

+ (BOOL) allowsMultipleInstances
{
    return NO;
}

+ (NSString*) description
{
    return @"meta-driver";
}

+ (NSString*) deviceName
{
    return nil;
}

#pragma mark -

+ (BOOL) loadBackend
{
    return NO;
}

+ (BOOL) unloadBackend
{
    return NO;
}

#pragma mark -

- (enum WaveDriverType) type
{
    return [[self class] type];
}

- (BOOL) allowsInjection
{
    return [[self class] allowsInjection];
}

- (BOOL) wantsIPAndPort
{
    return [[self class] wantsIPAndPort];
}

- (BOOL) allowsChannelHopping
{
    return [[self class] allowsChannelHopping];
}

- (BOOL) allowsMultipleInstances
{
    return [[self class] allowsMultipleInstances];
}

- (BOOL) unloadBackend
{
    return [[self class] unloadBackend];
}

- (NSString*) deviceName
{
    return [[self class] deviceName];
}

#pragma mark -

- (NSComparisonResult)compareDrivers:(WaveDriver *)driver
{
    return [[driver deviceName] compare:[self deviceName]];
}

#pragma mark -

- (BOOL)setConfiguration:(NSDictionary*)dict 
{
    NSUInteger i;
    NSUserDefaults *sets;
    NSMutableArray *a;
    
	_config = dict;
    
    _firstChannel = [_config[@"firstChannel"] intValue];
    if (_firstChannel == 0)
    {
        _firstChannel = 1;
    }
    _currentChannel = _firstChannel;

    _fcc = NO;
    _etsi = NO;
    _hopFailure = 0;
    _lastChannel = 0;
    
    _useChannel = _config[@"useChannels"];
    
    if ([_useChannel containsObject:@(13)] ||
        [_useChannel containsObject:@(13)] ||
        [_useChannel containsObject:@(11)]) _fcc = YES;
    if ([_useChannel containsObject:@(13)]) _etsi = YES;
    
    if ([_useChannel count] > 1) _hop = YES;
    else _hop = NO;
    
    _autoAdjustTimer = [_config[@"autoAdjustTimer"] boolValue];
    
    sets = [NSUserDefaults standardUserDefaults];
    a = [[sets objectForKey:@"ActiveDrivers"] mutableCopy];
    for (i = 0; i < [a count]; ++i)
    {
        if ([a[i][@"deviceName"] isEqualToString:[self deviceName]]) 
        {
            a[i] = dict;
        }
    }
    [sets setObject:a forKey:@"ActiveDrivers"];

    return YES;
}

- (NSDictionary*)configuration
{
    return _config;
}

- (BOOL)ETSI
{
    return _etsi;
}

- (BOOL)FCC
{
    return _fcc;
}

- (BOOL)hopping
{
    return _hop;
}

- (BOOL)autoAdjustTimer
{
    return _autoAdjustTimer;
}

#pragma mark -

- (UInt16) getChannel
{
    if (![self allowsChannelHopping]) return 0;

    return _currentChannel;
}

- (BOOL) setChannel:  (UInt16)newChannel
{
    return NO;
}

- (BOOL) startCapture:(UInt16)newChannel
{
    return YES;
}

- (BOOL) stopCapture
{
    return YES;
}

- (BOOL) sleepDriver
{
    return YES;
}

- (BOOL) wakeDriver
{
    return YES;
}

- (void) tryToSetChannel: (NSInteger) channel
{
    [self setChannel:channel];

    NSInteger i;
    for(i = 0; i < 20; ++i)
    {
        _currentChannel = [self getChannelUnCached];
        if (_currentChannel == channel)
            break;
    }
    if (i == 20)
    {
        [self stopCapture];
        [self startCapture:channel];
        _currentChannel = [self getChannelUnCached];
    }
    
}

- (void)hopToNextChannel
{
    if ( _useChannel.count == 0 ) return;   // Paranoia...

    // This works even if _currentChannel is invalid
    NSInteger curPos = [_useChannel indexOfObject:@(_currentChannel)];
    if (curPos == NSNotFound ||         // _currentChannel == 0 OR
        curPos+1 >= _useChannel.count)  // scanned all channels
    {
        // Back to the first channel
        curPos = -1;
    }
    NSInteger nextChannel = [_useChannel[curPos+1] integerValue];

    if (!_hop)
    {
        [self tryToSetChannel: nextChannel];
        return;
    }
    
    if (_autoAdjustTimer && (_packets!=0))
    {
        if (_autoRepeat < 1)
        {
            ++_autoRepeat;
            return;
        }
        else
        {
            _autoRepeat = 0;
        }
        _packets = 0;
    }
    
    //set the channel and make sure it is set
    //but do not force it too bad
    [self tryToSetChannel: nextChannel];

    //see if we can switching channel was successful, otherwise the card does may be not support the card
    if (_lastChannel == _currentChannel)
    {
        ++_hopFailure;
        if (_hopFailure >= 5)
        {
            _hopFailure = 0;
            NSMutableArray *useChannel = [_useChannel mutableCopy];
            if (nextChannel == 12)
            {
                // Assume FCC jurisdiction and disable channels 12-14
                DBNSLog(@"Setting channel 12 failed; assuming FCC jurisdiction. KisMAC will disable channels 12-14.");
                _fcc = YES;
                [useChannel removeObject:@(14)];
                [useChannel removeObject:@(13)];
                [useChannel removeObject:@(12)];
            }
            else
            {
                DBNSLog(@"Looks like your card does not support channel %@. KisMAC will disable this channel.", @(nextChannel));
                [useChannel removeObject:@(nextChannel)];
                if (nextChannel == 14)
                    _etsi = YES;
            }
            _useChannel = [useChannel copy];
        }
    }
    else
    {
        _hopFailure = 0;
        _lastChannel = _currentChannel;
    }
}

#pragma mark -

- (NSArray*) networksInRange
{
    return nil;
}

- (KFrame*) nextFrame
{
    return nil;
}

#pragma mark -

-(BOOL) startedScanning
{
	return YES;
}

-(BOOL) stoppedScanning
{
	return YES;
}

#pragma mark -
#pragma mark Sending frame
#pragma mark

-(BOOL) sendKFrame:(KFrame *)f howMany:(int)howMany atInterval:(int)interval
{
    return NO;
}

-(BOOL) sendKFrame:(KFrame *)f howMany:(int)howMany atInterval:(int)interval notifyTarget:(id)target notifySelectorString:(NSString *)selector
{
    return NO;
}

-(BOOL) stopSendingFrames
{
    return NO;
}

#pragma mark -

- (UInt16) allowedChannels
{
    return 0xFFFF;
}

#pragma mark -

- (NSArray *) permittedRates
{
    if (!_permittedRates)
    {
        _permittedRates = @[];
    }
    
    return _permittedRates;
}

- (KMRate) currentRate
{
	return _currentRate;
}

- (BOOL) setCurrentRate: (KMRate)rate
{
	_currentRate = rate;
    
	return YES;
}

@end
