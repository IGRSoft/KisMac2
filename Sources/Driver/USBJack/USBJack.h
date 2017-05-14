/*
        
        File:			USBIntersil.h
        Program:		KisMAC
	Author:			Michael Roßberg
				mick@binaervarianz.de
	Description:		KisMAC is a wireless stumbler for MacOS X.
                
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
#ifndef __USB_JACK
#define __USB_JACK

#include <Cocoa/Cocoa.h>
#include <IOKit/usb/IOUSBLib.h>
#include <pthread.h>
#include "../../Core/80211b.h"
#include "../../Core/KisMAC80211.h"
#include <unistd.h>
#include "prism2.h"
#include "structs.h"
#include <CoreFoundation/CoreFoundation.h>

#define RING_SLOT_NUM 1000

struct __frameRingSlot {
    unsigned char state;
#define FRAME_SLOT_FREE 0
#define FRAME_SLOT_USED 1
    UInt16 len;
    UInt16 channel;
    KFrame frame;
};

struct __frameRing {
    NSUInteger readIdx;
    NSUInteger writeIdx;
    NSUInteger received;
    NSUInteger dropped;
    struct __frameRingSlot slots[RING_SLOT_NUM];
};



class USBJack {
public:
    virtual BOOL    startCapture(UInt16 channel);
    virtual BOOL    stopCapture();
    virtual BOOL    getChannel(UInt16* channel);
    virtual BOOL    getAllowedChannels(UInt16* channel);
    virtual BOOL    setChannel(UInt16 channel);

    BOOL            devicePresent();
    BOOL            deviceMatched();
    
    KFrame *receiveFrame();
    virtual BOOL    sendKFrame(KFrame* data);
    
    void    startMatching();
    virtual IOReturn    _init();
    USBJack();
    virtual ~USBJack();
    
protected:
    BOOL    run();
    BOOL    stopRun();
    
    NSInteger kInterruptPipe;
    NSInteger kOutPipe;
    NSInteger kInPipe; 
    
    BOOL    _matchingDone;
    
    typedef NS_ENUM(NSUInteger, deviceTypes)
    {
        intersil = 1,
        zydas,
        ralink,
		rt73,
        rtl8187
    };

    IOReturn    _sendFrame(UInt8* data, IOByteCount size);
    
    virtual IOReturn    _reset();
    
    virtual char *      getPlistFile() = 0;
    BOOL                loadPropertyList();
    
    void                _lockDevice();
    void                _unlockDevice();
    
    IOReturn            _configureAnchorDevice(IOUSBDeviceInterface197 **dev);
    IOReturn            _findInterfaces(IOUSBDeviceInterface197 **dev);
    
    BOOL                _attachDevice();
    static void         _addDevice(void *refCon, io_iterator_t iterator);
    static void         _handleDeviceRemoval(void *refCon, io_iterator_t iterator);
    static void         _DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument);
    static void         _interruptReceived(void *refCon, IOReturn result, void *arg0);

    NSInteger                 initFrameQueue(void);
    NSInteger                 destroyFrameQueue(void);
    NSInteger                 insertFrameIntoQueue(void *f, UInt16 len, UInt16 channel);
    KFrame *            getFrameFromQueue(UInt16 *len, UInt16 *channel);
    
	// Method for convert driver native data to KFrame
    virtual BOOL        _massagePacket(void *inBuf, void *outBuf, UInt16 len, UInt16 channel);	

    // Driver specific packet handler
    virtual void        _rawFrameReceived(NSUInteger len);

    static void         _runCFRunLoop(USBJack* me);
  
    IOUSBDeviceInterface197 **_foundDevices[10];
    NSInteger         _numDevices;

//    SInt32                      _vendorID;
//    SInt32                      _productID;
    io_object_t                 _notification;
    
    char * _plistFile;
    BOOL                        _devicePresent;
    BOOL                        _deviceInit;
    BOOL                        _deviceMatched;

    BOOL                        _stayUp;
    BOOL                        _isSending;
    BOOL                        _isEnabled;
    SInt16                      _firmwareType;
    
    CFRunLoopRef                _runLoop;
    UInt16                      _channel;
    IONotificationPortRef	_notifyPort;
    CFRunLoopSourceRef		_runLoopSource;
    io_iterator_t		_deviceAddedIter;
    io_iterator_t		_deviceRemovedIter;
    IOUSBInterfaceInterface220**   _interface;
    IOUSBDeviceInterface197**      _dev;           //save this so we can't use the same device twice!
    union _usbout               _outputBuffer;
    union _usbin                _inputBuffer;
    union _usbin                _receiveBuffer;

    KFrame                       _frameBuffer;
    UInt16                      _frameSize;
    
    struct __frameRing          *_frameRing;
    
    pthread_mutex_t             _wait_mutex;
    pthread_cond_t              _wait_cond;
    pthread_mutex_t             _recv_mutex;
    pthread_cond_t              _recv_cond;
    
    CFPropertyListRef           _vendorsPlist;

};


#endif
