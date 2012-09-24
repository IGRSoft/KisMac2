/*
        
        File:			ScriptAdditions.m
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

#import "ScriptAdditions.h"
#import "ScanController.h"
#import "ScanControllerScriptable.h"
#import "WaveHelper.h"
#import "MapView.h"

@implementation NSApplication (APLApplicationExtensions)

- (id)showNetworks:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] showNetworks]];
}
- (id)showTraffic:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] showTrafficView]];
}
- (id)showMap:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] showMap]];
}
- (id)showDetails:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] showDetails]];
}

#pragma mark -

- (id)startScan:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] startScan]];
}
- (id)stopScan:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] stopScan]];
}
- (id)toggleScan:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] toggleScan]];
}

#pragma mark -

- (id)new:(NSScriptCommand *)command 
{
    return [[NSNumber numberWithBool:[(ScanController*)[NSApp delegate] new]] retain];
}

- (id)save:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] save:[command directParameter]]];
}

- (id)saveAs:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] saveAs:[command directParameter]]];
}

- (id)importKisMAC:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] importKisMAC:[command directParameter]]];
}
- (id)importImageForMap:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] importImageForMap:[command directParameter]]];
}
- (id)importPCAP:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] importPCAP:[command directParameter]]];
}
- (id)exportKML:(NSScriptCommand *)command {
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] exportKML:[command directParameter]]];
}


- (id)downloadMap:(NSScriptCommand*)command {
    NSDictionary *args = [command arguments];
    NSSize size;
    waypoint w;
    int zoom;
    NSString *server;
    
    server = [command directParameter];
    size.width = [[args objectForKey:@"Width"] doubleValue];
    size.height = [[args objectForKey:@"Height"] doubleValue];
    w._lat  = [[args objectForKey:@"Latitude"] doubleValue];
    w._long = [[args objectForKey:@"Longitude"] doubleValue];
    zoom = [[args objectForKey:@"Zoom"] intValue];
    
    BOOL ret = [(ScanController*)[NSApp delegate] downloadMapFrom:server forPoint:w resolution:size zoomLevel:zoom];
    return [NSNumber numberWithBool:ret];
}

#pragma mark -

- (id)selectNetworkWithBSSID:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] selectNetworkWithBSSID:[command directParameter]]];
}

- (id)selectNetworkAtIndex:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] selectNetworkAtIndex:[command directParameter]]];
}

- (id)networkCount:(NSScriptCommand *)command {
   return [NSNumber numberWithInt:[(ScanController*)[NSApp delegate] networkCount]];
}

#pragma mark -

- (id)busy:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] isBusy]];
}

#pragma mark -

- (id)bruteforceNewsham:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] bruteforceNewsham]];
}

- (id)bruteforce40bitLow:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] bruteforce40bitLow]];
}

- (id)bruteforce40bitAlpha:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] bruteforce40bitAlpha]];
}

- (id)bruteforce40bitAll:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] bruteforce40bitAll]];
}

- (id)wordlist40bitApple:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] wordlist40bitApple:[command directParameter]]];
}

- (id)wordlist104bitApple:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] wordlist104bitApple:[command directParameter]]];
}

- (id)wordlist104bitMD5:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] wordlist104bitMD5:[command directParameter]]];
}

- (id)wordlistWPA:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] wordlistWPA:[command directParameter]]];
}

- (id)wordlistLEAP:(NSScriptCommand *)command {
   return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] wordlistLEAP:[command directParameter]]];
}

- (id)weakSchedulingAttack:(NSScriptCommand *)command {
    NSDictionary *args = [command arguments];
    int keyID, keyLen;
    
    keyID = [[args objectForKey:@"KeyID"] intValue];
    keyLen = [[args objectForKey:@"KeyLen"] intValue];
    if (keyLen == 0) keyLen = 13;
    
    return [NSNumber numberWithBool:[(ScanController*)[NSApp delegate] weakSchedulingAttackForKeyLen:keyLen andKeyID:keyID]];
}

#pragma mark -

- (id)showNetworksInMap:(NSScriptCommand*)command {
    [[WaveHelper mapView] setShowNetworks:[[command directParameter] boolValue]];
    return [NSNumber numberWithBool:YES];    
}

- (id)showTraceInMap:(NSScriptCommand*)command {
    [[WaveHelper mapView] setShowTrace:[[command directParameter] boolValue]];
    return [NSNumber numberWithBool:YES];    
}

- (id)setCurrentPosition:(NSScriptCommand*)command {
    NSDictionary *args = [command arguments];
    BOOL ret = [[WaveHelper mapView] setCurrentPostionToLatitude:[[args objectForKey:@"Latitude"] doubleValue] andLongitude:[[args objectForKey:@"Longitude"] doubleValue]];
    return [NSNumber numberWithBool:ret];
}

- (id)setWaypoint:(NSScriptCommand*)command {
    NSDictionary *args = [command arguments];
    NSPoint p;
    waypoint coord;
    int which;
    
    which = [[command directParameter] intValue];
    p.x = [[args objectForKey:@"X"] doubleValue];
    p.y = [[args objectForKey:@"Y"] doubleValue];
    coord._lat  = [[args objectForKey:@"Latitude"] doubleValue];
    coord._long = [[args objectForKey:@"Longitude"] doubleValue];
    
    BOOL ret = [[WaveHelper mapView] setWaypoint:which toPoint:p atCoordinate:coord];
    return [NSNumber numberWithBool:ret];
}

@end
