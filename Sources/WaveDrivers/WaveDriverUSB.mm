/*
 
 File:			WaveDriverUSB.m
 Program:		KisMAC
 Author:		Michael Roßberg
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

#import "WaveDriverUSBIntersil.h"
#import "WaveHelper.h"

@implementation WaveDriverUSB

- (id)init {
    self=[super init];

    if (!self)
        return nil;
    
    _driver = nil;
    
    if(![self wakeDriver])
    {
        //we didn't find a card, we can't proceed
        //destroy the driver
        
        delete(_driver);
        _driver = nil;
        return nil;
    }
    
    return self;
}

#pragma mark -

+ (enum WaveDriverType) type {
    return passiveDriver;
}

+ (BOOL) allowsInjection {
    return YES;
}

+ (BOOL) allowsChannelHopping {
    return YES;
}

+ (BOOL) allowsMultipleInstances {
    return YES;  //may be later
}

+ (NSString*) description {
    return NSLocalizedString(@"USB device, passive mode", "long driver description");
}

+ (NSString*) deviceName {
    return NSLocalizedString(@"USB device", "short driver description");
}

#pragma mark -

+ (BOOL) loadBackend {
    return YES;
}

+ (BOOL) unloadBackend {
       return YES;
}

#pragma mark -

- (UInt16) getChannelUnCached
{
    UInt16 channel = 0;
    BOOL success = FALSE;
    
    //make sure we have a driver before we ask it for its channel
    if(_driver)
    {
        success = _driver->getChannel(&channel);
    }
    
    //channel 0 indicates error
    if(!success) channel = 0;
    
    return channel;
}

- (BOOL) setChannel:(UInt16)newChannel {
    if ((([self allowedChannels] >> (newChannel - 1)) & 0x0001) == 0)
        return NO;
    
    return _driver->setChannel(newChannel);
}

- (BOOL) startCapture:(UInt16)newChannel
{
    BOOL success = FALSE;
    
    if (newChannel == 0) newChannel = _firstChannel;
    
    //if there is no driver, success will remain false
    if(_driver)
    {
        //if the usb device is not there, see if we can find it
        if(!_driver->devicePresent())
        {
            [self wakeDriver];
        }
        success = _driver->startCapture(newChannel);
    }
    
    return success;
}

- (BOOL) stopCapture
{
    BOOL success = FALSE;
    
    //if there is no driver, success will remain false
    if(_driver)
    {
        success = _driver->stopCapture();
    }
        
    return success; 
}

- (BOOL) sleepDriver
{
    if(_driver) delete(_driver);
    _driver = nil;
    return YES;
}

- (BOOL) wakeDriver
{
    return YES;
}

#pragma mark -

- (KFrame *) nextFrame {
    KFrame *f = NULL;
    BOOL success;
    
    //make sure we have _driver and the device is actually there
    success = (_driver && _driver->devicePresent());
    
    if(success) {
         f = _driver->receiveFrame();
    }

    if (!f) {
        //there was a driver error, usb device is probably gone
        NSRunCriticalAlertPanel(NSLocalizedString(@"USB device error", "Error box title"),
                                NSLocalizedString(@"USB device error description", "LONG Error description"),
                                //@"A driver error occured with your USB device, make sure it is properly connected. Scanning will "
                                //"be canceled. Errors may have be printed to console.log."
                                OK, nil, nil);
    }
    else
    {
        ++_packets;
    }
    
    return f;
}

#pragma mark -
#pragma mark Injection
#pragma mark -

- (void)doInjection:(NSDictionary *)d {

	@autoreleasepool {
		NSData *data = d[@"data"];
		KFrame *f = (KFrame *)[data bytes];
		NSNumber *howM = d[@"howMany"];
		NSString *sel = d[@"selector"];
		SEL selector = NSSelectorFromString(sel);
		id target = d[@"target"];
		NSThread *thr = d[@"thread"];
		NSInteger howMany = [howM intValue];
		DBNSLog(@"doInj HowMany %@", @(howMany));
		if (howMany == -1) {
			while(_transmitting) {
				_driver->sendKFrame(f);
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:_interval]];
			}
		} else {
			while(_transmitting && howMany) {
				_driver->sendKFrame(f);
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:_interval]];
				howMany--;
			}
		}
		if (target && selector) {
			[target performSelector:selector onThread:thr withObject:nil waitUntilDone:NO];
		}
	}
}

-(BOOL) sendKFrame:(KFrame *)f howMany:(NSInteger)howMany atInterval:(NSInteger)interval notifyTarget:(id)target notifySelectorString:(NSString *)selector {
    NSThread *thr = [NSThread currentThread];
    if (howMany != 0) {
        NSData *data = [NSData dataWithBytes:f length:sizeof(KFrame)];
        NSNumber *howM = @(howMany);
        NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys: data, @"data", howM, @"howMany", thr, @"thread", target, @"target", selector, @"selector", nil];
        [self stopSendingFrames];
        _transmitting = YES;
        _interval = (CGFloat)interval / 1000.0;
        [NSThread detachNewThreadSelector:@selector(doInjection:) toTarget:self withObject:d];
    } else {
        _driver->sendKFrame(f);
        if (target && selector) {
            SEL sel = NSSelectorFromString(selector);
			NSMethodSignature *methodSignature = [target methodSignatureForSelector:sel];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
			[invocation setSelector:sel];
			[invocation invoke];
        }
    }
    return YES;
}

-(BOOL) sendKFrame:(KFrame *)f howMany:(NSInteger)howMany atInterval:(NSInteger)interval {
    return [self sendKFrame:f howMany:howMany atInterval:interval notifyTarget:nil notifySelectorString:nil];
}
-(BOOL) stopSendingFrames {
    _transmitting = NO;
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:_interval]];
    return YES;
}

#pragma mark -

- (UInt16) allowedChannels
{
    UInt16 channels;
    
    if (_allowedChannels)
        return _allowedChannels;
    
    if (_driver->getAllowedChannels(&channels))
    {
        _allowedChannels = channels;
        
        return channels;
    }
    
    return 0xFFFF;
}

#pragma mark -

-(void) dealloc {
    [self stopSendingFrames];
    
    [self sleepDriver];

    if (_driver)
        delete (_driver);
}

@end
