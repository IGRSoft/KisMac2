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

static int AirPortInstances = 0;
static WaveDriverAirport * staticInstance = nil;

@implementation WaveDriverAirport

- (id)init 
{
    [super init];
    NSArray * availableInterfaces;
    BOOL success = NO;
    NSError * error;
    
    if(nil == staticInstance)
    {        
        //first we must find an interface
        availableInterfaces = [CWInterface supportedInterfaces];
        
        //CFShow(availableInterfaces);
        
        //for now just grab the first one
        if([availableInterfaces count] > 0)
        {
            airportInterface = [[CWInterface interfaceWithName: 
                                             [availableInterfaces objectAtIndex: 0]] retain];
            //CFShow(airportInterface);
            if(YES == airportInterface.power)
            {
                success = YES;
            }
            else
            {
                success = [airportInterface setPower: YES error: &error];
                if(!success)
                {
                    CFShow(error);
                }
            }
        }
        
        networks = nil;
        
        if(!success)
        {
            self = nil;
        }

        staticInstance = self;
        
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
    NSArray * availableInterfaces;
    
    availableInterfaces = [CWInterface supportedInterfaces];
    
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
    NSDictionary *params;
    NSError * error = nil;
        
    //don't merge duplicate ssids
    params = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithBool:NO], kCWScanKeyMerge,
                               [NSNumber numberWithInt:kCWScanTypePassive], kCWScanKeyScanType,
                               [NSNumber numberWithInteger:0], kCWScanKeyRestTime,
                               [NSNumber numberWithInteger:10], kCWScanKeyDwellTime, nil];
    networks = [airportInterface scanForNetworksWithParameters:params error: &error]; 
  
    return networks;
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
    NSDictionary * assocDict;
    NSEnumerator * enumerator;
    bool foundNet = NO;
    bool success = NO;

    if(nil == networks)
    {
        networks = [self networksInRange];
    }
    
    enumerator = [networks objectEnumerator];
    
    while((netToJoin = [enumerator nextObject]) != nil)
    {
        if(!memcmp([netToJoin.bssidData bytes], bssid, 6))
        {
            foundNet = YES;
            break;
        }
    }
    
    if(YES == foundNet)
    {
        assocDict = [NSDictionary dictionaryWithObjectsAndKeys: passwd, kCWAssocKeyPassphrase,
                     nil];
        success = [airportInterface associateToNetwork: netToJoin parameters: assocDict error:&error];
    }
    
    if(error)
    {
        CFShow(error);
    }
    return success;
}

#pragma mark -

-(void) dealloc 
{
    [airportInterface release];
    airportInterface = nil;
    [super dealloc];
}


@end
