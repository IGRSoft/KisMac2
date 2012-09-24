//
//  WavePlugin.h
//  KisMAC
//
//  Created by pr0gg3d on 12/09/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WavePacket.h"
#import "WaveDriver.h"
#import "WaveNet.h"
#import "WaveClient.h"
#import "WaveHelper.h"
#import "WaveContainer.h"

typedef enum _WavePluginStatus {
    WavePluginIdle            = 0,
    WavePluginRunning         = 1,
} WavePluginStatus;

typedef enum _WavePluginPacketResponse {
    WavePluginPacketResponseContinue = 1,
    WavePluginPacketResponseCatched  = 2,
} WavePluginPacketResponse;

@interface WavePlugin : NSObject {
    WavePluginStatus  _status;
    WaveDriver *    _driver;
    bool            _stopFlag;
    
    WaveNet *_networkInTest;
}

- (id) initWithDriver:(WaveDriver *)driver;
- (bool) startTest;
- (WavePluginStatus) status;
- (bool) stopTest;
- (WavePluginPacketResponse) gotPacket:(WavePacket *)packet fromDriver:(WaveDriver *)driver;

@end
