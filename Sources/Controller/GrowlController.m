/*
        
        File:			GrowlController.m
        Program:		KisMAC
		Description:	KisMAC is a wireless stumbler for MacOS X.
		Author:			themacuser at gmail dot com
        
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

#import "GrowlController.h"

@implementation GrowlController

- (id)init
{
	return [super init];
}

- (void)dealloc
{
	[super dealloc];
}

- (void)registerGrowl
{
	NSBundle *myBundle = [NSBundle bundleForClass:[GrowlController class]];
	NSString *growlPath = [[myBundle privateFrameworksPath]
	stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	if (growlBundle && [growlBundle load]) {
		[GrowlApplicationBridge setGrowlDelegate:self];
	} else {
		NSLog(@"Could not load Growl.framework");
	}
}

#pragma mark Growl Notifications

+ (void)notifyGrowlOpenNetwork:(NSString *)notname SSID:(NSString *)SSID BSSID:(NSString *)BSSID signal:(int)signal channel:(int)channel
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"Open network found:\nSSID: %@\nBSSID: %@\nSignal: %i\nChannel: %i",SSID,BSSID,signal,channel]
   notificationName:@"Open Network Found"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-noenc"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlWEPNetwork:(NSString *)notname SSID:(NSString *)SSID BSSID:(NSString *)BSSID signal:(int)signal channel:(int)channel
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"WEP network found:\nSSID: %@\nBSSID: %@\nSignal: %i\nChannel: %i",SSID,BSSID,signal,channel]
   notificationName:@"Closed Network Found"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-wep"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlWPANetwork:(NSString *)notname SSID:(NSString *)SSID BSSID:(NSString *)BSSID signal:(int)signal channel:(int)channel
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"WPA network found:\nSSID: %@\nBSSID: %@\nSignal: %i\nChannel: %i",SSID,BSSID,signal,channel]
   notificationName:@"Closed Network Found"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-wpa"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlUnknownNetwork:(NSString *)notname SSID:(NSString *)SSID BSSID:(NSString *)BSSID signal:(int)signal channel:(int)channel
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"Unknown network found:\nSSID: %@\nBSSID: %@\nSignal: %i\nChannel: %i",SSID,BSSID,signal,channel]
   notificationName:@"Closed Network Found"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"NetworkStrange"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}
+ (void)notifyGrowlLEAPNetwork:(NSString *)notname SSID:(NSString *)SSID BSSID:(NSString *)BSSID signal:(int)signal channel:(int)channel
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"LEAP network found:\nSSID:%@\nBSSID:%@\nSignal:%i\nChannel:%i",SSID,BSSID,signal,channel]
   notificationName:@"Closed Network Found"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-leap"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlProbeRequest:(NSString *)notname BSSID:(NSString *)BSSID signal:(int)signal
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"Probe Request Received:\nMAC: %@\nSignal: %i",BSSID,signal]
   notificationName:@"Probe Request Received"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-probe"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlStartScan
{
    NSData * iconData = nil;
    NSImage * image = [NSImage imageNamed:@"devil.icns"];
                       
    if(image != nil)
    {
        iconData = [image TIFFRepresentation];
    }
    
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:@"Starting Scan..."
   notificationName:@"Scan Started/Stopped"
		   iconData:iconData
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlStopScan
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:@"Stopping Scan..."
   notificationName:@"Scan Started/Stopped"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"devil.icns"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlWPAChallenge:(NSString *)notname mac:(NSString *)mac bssid:(NSString *)bssid
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"WPA Challenge received:\nMAC: %@\nBSSID: %@",mac,bssid]
   notificationName:@"WPA Challenge/Response"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-wpa-challenge"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlWPAResponse:(NSString *)notname mac:(NSString *)mac bssid:(NSString *)bssid
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"WPA Response received:\nMAC: %@\nBSSID: %@",mac,bssid]
   notificationName:@"WPA Challenge/Response"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-wpa-response"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

+ (void)notifyGrowlSSIDRevealed:(NSString *)notname BSSID:(NSString *)BSSID SSID:(NSString *)SSID
{
	[GrowlApplicationBridge
	notifyWithTitle:@"KisMAC"
		description:[NSString stringWithFormat:@"Hidden SSID Revealed:\nSSID: %@\nBSSID: %@",SSID,BSSID]
   notificationName:@"Hidden SSID Revealed"
		   iconData:[NSData dataWithData:[[NSImage imageNamed:@"growl-ap-revealed"] TIFFRepresentation]]
		   priority:0
		   isSticky:NO
	   clickContext:nil];
}

#pragma mark Growl Methods

- (NSString *)applicationNameForGrowl {
	return @"KisMAC";
}

- (NSDictionary *)registrationDictionaryForGrowl {
	NSArray *allNotifications = [NSArray arrayWithObjects:@"Scan Started/Stopped",@"Open Network Found",@"Closed Network Found",@"Probe Request Received",@"WPA Challenge/Response",@"Hidden SSID Revealed",nil];
	NSArray *defaultNotifications = [NSArray arrayWithObjects:@"Scan Started/Stopped",@"Open Network Found",@"Closed Network Found",@"WPA Challenge/Response",@"Hidden SSID Revealed",nil];
	NSDictionary *registrationDict = [NSDictionary dictionaryWithObjectsAndKeys:allNotifications, GROWL_NOTIFICATIONS_ALL, defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
	return registrationDict;
}
	
@end
