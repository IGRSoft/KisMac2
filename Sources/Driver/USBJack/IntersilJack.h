//
//  IntersilJack.h
//  KisMAC
//
//  Created by Geoffrey Kruse on 5/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "KMCommon.h"
#import "USBJack.h"

class IntersilJack: public USBJack
{
public:

    IntersilJack();
    ~IntersilJack();
    
    IOReturn    _init();
    IOReturn    _reset();
    
    char   *getPlistFile();
    BOOL    startCapture(UInt16 channel);
    BOOL    stopCapture();
    BOOL    getChannel(UInt16* channel);
    BOOL    getAllowedChannels(UInt16* channel);
    BOOL    setChannel(UInt16 channel);
    NSInteger     WriteTxDescriptor(WLFrame * theFrame, KMRate kmrate);
    BOOL    sendKFrame(KFrame *frame);
    BOOL    _massagePacket(void *inBuf, void *outBuf, UInt16 len, UInt16 channel);
    
    IOReturn    _doCommand(enum WLCommandCode cmd, UInt16 param0, UInt16 param1 = 0, UInt16 param2 = 0);
    IOReturn    _doCommandNoWait(enum WLCommandCode cmd, UInt16 param0, UInt16 param1 = 0, UInt16 param2 = 0);

#if BYTE_ORDER == BIG_ENDIAN
    IOReturn    _getRecord(UInt16 rid, void* buf, UInt32* n, BOOL swapBytes = true);
    IOReturn    _setRecord(UInt16 rid, const void* buf, UInt32 n, BOOL swapBytes = true);
#else 
    IOReturn    _getRecord(UInt16 rid, void* buf, UInt32* n, BOOL swapBytes = false); 
    IOReturn    _setRecord(UInt16 rid, const void* buf, UInt32 n, BOOL swapBytes = false); 
#endif

    IOReturn    _getValue(UInt16 rid, UInt16* v);
    IOReturn    _setValue(UInt16 rid, UInt16 v);
    IOReturn    _writeWaitForResponse(UInt32 size);
    IOReturn    _getHardwareAddress(struct WLHardwareAddress* addr);
    IOReturn    _getIdentity(WLIdentity* wli);
    NSInteger         _getFirmwareType();
    IOReturn    _disable();
    IOReturn    _enable();
    
private:
        //NSInteger temp;
};


