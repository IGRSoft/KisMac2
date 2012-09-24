/*
        
        File:			WaveDriverAirport.m
        Program:		KisMAC
		Author:			Geoffrey Kruse
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

#import "WaveDriverAirport.h"
#import "WaveHelper.h"
#include <dlfcn.h>

static int AirPortInstances = 0;
static WaveDriverAirport * staticInstance = nil;

@implementation WaveDriverAirport

- (id)init 
{
    if (!(self = [super init])) return nil;
    NSSet * availableInterfaces;
    BOOL success = NO;
    NSError * error;
    
    if(nil == staticInstance)
    {        
        //first we must find an interface
        availableInterfaces = [CWInterface interfaceNames];
        
        //CFShow(availableInterfaces);
        
        //for now just grab the first one
        if([availableInterfaces count] > 0)
        {
            airportInterface = [CWInterface interfaceWithName: 
                                             [availableInterfaces allObjects][0]];
            //CFShow(airportInterface);
            if(YES == airportInterface.powerOn)
            {
                success = YES;
            }
            else
            {
                success = [airportInterface setPower: YES error: &error];
                if(!success)
                {
                    CFShow((__bridge CFTypeRef)(error));
                }
            }
        }
        
        networks = nil;
        
        if(!success)
        {
            self = nil;
        }

        staticInstance = self;
		
		libHandle = dlopen("/System/Library/Frameworks/Preferences.framework/Preferences", RTLD_LAZY);
		open = dlsym(libHandle, "Apple80211Open");
		bind = dlsym(libHandle, "Apple80211BindToInterface");
		close = dlsym(libHandle, "Apple80211Close");
		scan = dlsym(libHandle, "Apple80211Scan");
		
		open(&airportHandle);
		bind(airportHandle, @"en0");
        
        return self;
    }
    
    return staticInstance;
}

+(int) airportInstanceCount 
{
    return AirPortInstances;
}

+(WaveDriverAirport*)sharedInstance
{
    if(nil == staticInstance)
    {
        staticInstance = [[WaveDriverAirport alloc] init];
    }
    return staticInstance;
}

#pragma mark -

+ (enum WaveDriverType) type 
{
    return activeDriver;
}

+ (NSString*) description 
{
    return NSLocalizedString(@"Apple Airport or Airport Extreme card, active mode", 
                                                        "long driver description");
}

+ (NSString*) deviceName 
{
    return NSLocalizedString(@"Airport Card", "short driver description");
}

#pragma mark -
//apple knows best, ask api if wireless is available
+ (bool) loadBackend 
{
    NSSet * availableInterfaces;
    
    availableInterfaces = [CWInterface interfaceNames];
    
    return ([availableInterfaces count] > 0);
}

+ (bool) unloadBackend 
{
    return YES;
}

#pragma mark -

//this is the same as what you would see in the airport menu
//don't expect any more information than that in active mode
- (NSArray*) networksInRange 
{
	NSArray *scan_networks;
	NSDictionary *parameters = [[NSDictionary alloc] init];
	scan(airportHandle, &scan_networks, (__bridge void *)(parameters));
	int i;
	for (i = 0; i < [scan_networks count]; i++) {
		if([networks objectForKey:[[scan_networks objectAtIndex: i] objectForKey:@"BSSID"]] != nil
		   && ![[networks objectForKey:[[scan_networks objectAtIndex: i] objectForKey:@"BSSID"]] isEqualToDictionary:[scan_networks objectAtIndex: i]])
		{
			[networks setObject:[scan_networks objectAtIndex: i] forKey:[[scan_networks objectAtIndex: i] objectForKey:@"BSSID"]];
		}
	}
	
	 
	return [NSArray arrayWithObject: networks];
}

#pragma mark -

//active driver does not support changing channels
- (void) hopToNextChannel 
{
	return;
}

- (bool)joinBSSID:(UInt8*) bssid withPassword:(NSString*)passwd;
{
    CWNetwork * netToJoin;
    NSError * error = nil;
    NSEnumerator * enumerator;
    bool foundNet = NO;
    bool success = NO;

    if(nil == networks)
    {
        networks = [[self networksInRange] objectAtIndex:0];
    }
    
    enumerator = [networks objectEnumerator];
    
    while((netToJoin = [enumerator nextObject]) != nil)
    {
		unsigned char macData[6] = {0};
		NSString* macString = [netToJoin bssid];
		if (macString && ([macString length] == 17)) {
			for (NSUInteger i = 0; i < 6; ++i) {
				NSString* part = [macString substringWithRange:NSMakeRange(i * 3, 2)];
				NSScanner* scanner = [NSScanner scannerWithString:part];
				unsigned int data = 0;
				if (![scanner scanHexInt:&data]) {
					data = 0;
				}
				macData[i] = (unsigned char) data;
			}
		}
		
        if(!memcmp(macData, bssid, 6))
        {
            foundNet = YES;
            break;
        }
    }
    
    if(YES == foundNet)
    {
		success = [airportInterface associateToNetwork:netToJoin password:passwd error:&error];
    }
    
    if(error)
    {
        CFShow((__bridge CFTypeRef)(error));
    }
    return success;
}

#pragma mark -

-(void) dealloc 
{
    airportInterface = nil;
}


@end
