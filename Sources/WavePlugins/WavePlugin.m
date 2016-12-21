/*
 
 File:			WavePlugin.m
 Program:		KisMAC
 Author:		pr0gg3d
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

#import "WavePlugin.h"

@implementation WavePlugin

#pragma mark -

- (id) initWithDriver:(WaveDriver *)driver
{
    if (!driver)
	{
        return nil;
    }
	
    self = [super init];
    
    if (!self)
	{
        return nil;
    }
    _driver = driver;
    
    _status = WavePluginIdle;
    _stopFlag = NO;
    
    return self;
}

- (void) dealloc
{
    
    _driver = nil;
}

#pragma mark -
#pragma mark Test control
#pragma mark -

- (bool) startTest
{
    // Checks if test is idle, otherwise return a problem
    if (_status != WavePluginIdle)
	{
        return NO;
    }
    
	_status = WavePluginRunning;
    // Perform test
    
	return YES;
}

- (bool) stopTest
{
    // Checks if test is running, otherwise ignore
    if (_status != WavePluginRunning)
	{
        return NO;
	}
    
	_stopFlag = YES;
    
	return YES;
}

- (WavePluginPacketResponse) gotPacket:(WavePacket *)packet fromDriver:(WaveDriver *)driver
{
    // Override in subclasses
    return WavePluginPacketResponseContinue;
}

- (WavePluginStatus) status
{
    return _status;
}

#pragma mark -

@end
