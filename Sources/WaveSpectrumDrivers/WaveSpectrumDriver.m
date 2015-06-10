/*
 
 File:			WaveSpectrumDriver.m
 Program:		KisMAC
 Author:		Francesco Del Degan
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

#import "WaveSpectrumDriver.h"
#include <mach/mach.h>
#include <IOKit/IOCFPlugIn.h>

static void RawDeviceAdded(void* refcon, io_iterator_t iterator)
{
    [(__bridge WaveSpectrumDriver*)refcon rawDeviceAdded:iterator];
}

@implementation WaveSpectrumDriver

- (id) init
{
    self = [super init];
    if (!self)
	{
        return nil;
	}
	
    [self wispy_init];
    return self;
}

- (void) wispy_init
{
    mach_port_t             masterPort = KERN_SUCCESS;
    CFRunLoopSourceRef      runLoopSource = NULL;
    kern_return_t           kr = kIOReturnSuccess;


    NSNumber* usbVendor = @0x1781;
    NSNumber* usbProduct = @0x083e;
    
    NSMutableDictionary* matchingDict = (__bridge NSMutableDictionary *)IOServiceMatching(kIOUSBDeviceClassName);
    [matchingDict setValue:usbVendor forKey:@"idVendor"];
    [matchingDict setValue:usbProduct forKey:@"idProduct"];
    DBNSLog(@"%@", matchingDict);
    //Create a master port for communication with the I/O Kit
    kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (kr || !masterPort)
    {
        CFRelease((__bridge CFTypeRef)(matchingDict));
        DBNSLog(@"ERR: Couldn’t create a master I/O Kit port(%08x)\n", kr);
		
        return;
    }
    _notifyPort = IONotificationPortCreate(masterPort);
    runLoopSource = IONotificationPortGetRunLoopSource (_notifyPort);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopSource, kCFRunLoopDefaultMode);
    kr = IOServiceAddMatchingNotification(_notifyPort, kIOFirstMatchNotification, (__bridge CFDictionaryRef)matchingDict, RawDeviceAdded, (__bridge void *)self, &_gRawAddedIter);
    
	if (kr)
	{
        return;
    }
    [self rawDeviceAdded:_gRawAddedIter];
    
	mach_port_deallocate (mach_task_self(), masterPort);
}

- (void) rawDeviceAdded:(io_iterator_t) iterator
{
    kern_return_t               kr = kIOReturnSuccess;
    io_service_t                usbDevice = NULL;
    IOCFPlugInInterface         **plugInInterface = NULL;
    HRESULT                     result = 0;
    SInt32                      score = 0;
    UInt16                      vendor = 0;
    UInt16                      product = 0;
    UInt16                      release = 0;
    DBNSLog(@"DEVICE ADDED");
	
    while ((usbDevice = IOIteratorNext(iterator)))
    {
        DBNSLog(@"OOO");
        //Create an intermediate plug-in
        kr = IOCreatePlugInInterfaceForService(usbDevice,
                                               kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
		
        if ((kIOReturnSuccess != kr) || !plugInInterface)
        {
            DBNSLog(@"Unable to create a plug-in (%08x)\n", kr);
            continue;
        }
        //Don’t need the device object after intermediate plug-in is created
        kr = IOObjectRelease(usbDevice);
        if ((kIOReturnSuccess != kr) || !plugInInterface)
        {
            DBNSLog(@"Unable to create a plug-in (%08x)\n", kr);
            continue;
        }
        //Now create the device interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,
                                                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                    (LPVOID *)&_dev);
        //Don’t need the intermediate plug-in after device interface
        //is created
        (*plugInInterface)->Release(plugInInterface);
        
        if (result || !_dev)
        {
            DBNSLog(@"Couldn’t create a device interface (%08x)\n",
                   (int) result);
            continue;
        }
        
        //Check these values for confirmation
        kr = (*_dev)->GetDeviceVendor(_dev, &vendor);
        if (kr != kIOReturnSuccess)
        {
            DBNSLog(@"Unable to open device: %08x\n", kr);
            (void) (*_dev)->Release(_dev);
            continue;
        }

        kr = (*_dev)->GetDeviceProduct(_dev, &product);
        if (kr != kIOReturnSuccess)
        {
            DBNSLog(@"Unable to open device: %08x\n", kr);
            (void) (*_dev)->Release(_dev);
            continue;
        }

        kr = (*_dev)->GetDeviceReleaseNumber(_dev, &release);
        if (kr != kIOReturnSuccess)
        {
            DBNSLog(@"Unable to open device: %08x\n", kr);
            (void) (*_dev)->Release(_dev);
            continue;
        }

        if ((vendor != 0x1781) || (product != 0x083e))
        {
            DBNSLog(@"Found unwanted device (vendor = %d, product = %d)\n",
                   vendor, product);
            (void) (*_dev)->Release(_dev);
            continue;
        }
        
        //Open the device to change its state
        kr = (*_dev)->USBDeviceOpen(_dev);
        if (kr != kIOReturnSuccess)
        {
            DBNSLog(@"Unable to open device: %08x\n", kr);
            (void) (*_dev)->Release(_dev);
            continue;
        }
        
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(getData:) userInfo:nil repeats:YES];
    }
}

- (void) getData: (NSTimer *)timer
{
    kern_return_t		kr = kIOReturnSuccess;
    char				buf[8];
    char				samples[84];
    IOUSBDevRequest     request;
	
    request.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBClass, kUSBInterface);
    request.bRequest = kUSBRqClearFeature;
    request.wValue = 0x3 << 8;
    request.wIndex = 0;
    request.pData = buf;
    request.wLength = 8;
    
    int i;
    while(1)
	{
        kr = (*_dev)->DeviceRequest(_dev, &request);
        if (kr != kIOReturnSuccess) {
            DBNSLog(@"nooooooo\n");
            break;
        }
        memcpy(samples+buf[0], buf+1, 7);
        if (buf[0] == 77) {
            for (i = 0 ; i < 84 ; ++i)
			{
                DBNSLog(@"%.2d ", samples[i]);
            }
            printf("\n");
            break;
        }
    }
    
}

- (void) closeDevice
{
    kern_return_t kr = kIOReturnSuccess;
	
    //Close this device and release object
    kr = (*_dev)->USBDeviceClose(_dev);
    if (kr != kIOReturnSuccess)
    {
        DBNSLog(@"Unable to close device: %08x\n", kr);
    }

    kr = (*_dev)->Release(_dev);
    if (kr != kIOReturnSuccess)
    {
        DBNSLog(@"Unable to release device: %08x\n", kr);
    }

    (*_dev) = NULL;
}

@end
