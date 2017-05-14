/*
 
 File:			GPSController.h
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

#include <CoreLocation/CoreLocation.h>

struct _position
{
    char dir;
    CGFloat coordinates;
};

@interface GPSController : NSObject <CLLocationManagerDelegate>
{
    BOOL      _gpsThreadUp;
    BOOL      _gpsShallRun;
    BOOL      _gpsdReconnect;
    BOOL      _reliable;
    BOOL      _tripmateMode;
    NSInteger _traceInterval;
    NSInteger _onNoFix;
    BOOL      _debugEnabled;
    NSInteger _linesRead;
    int       _serialFD;
    NSInteger _veldir;
    CGFloat   _velkt;
    CGFloat   _maxvel;
    CGFloat   _peakvel;
    NSInteger _numsat;
    CGFloat   _hdop;
    CGFloat   _sectordist;
    CGFloat   _sectortime;
    CGFloat   _totaldist;

    struct _position    _ns, _ew, _elev;
    
    NSDate   * _lastAdd;
    NSString * _position;
    NSString * _gpsDevice;
    NSDate   * _lastUpdate;
    NSDate   * _sectorStart;
    NSLock   * _gpsLock;
    NSString * _status;
    
    CLLocationManager * clManager;
}

- (BOOL)startForDevice:(NSString*) device;
- (BOOL)reliable;
- (void)resetTrace;
- (BOOL)gpsRunning;
- (void)setTraceInterval:(NSInteger)interval;
- (void)setTripmateMode:(BOOL)mode;
- (void)setOnNoFix:(NSInteger)onNoFix;
- (NSDate*)lastUpdate;
- (NSString*)NSCoord;
- (NSString*)EWCoord;
- (NSString*)ElevCoord;
- (NSString*)status;
- (void)setCurrentPointNS:(double)ns EW:(double)ew ELV:(double)elv;

- (waypoint)currentPoint;
- (void)stop;

- (void)writeDebugOutput:(BOOL)enable;

@end
