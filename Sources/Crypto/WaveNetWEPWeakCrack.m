/*
        
        File:			WaveNetWeakWEPCrack.m
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

#import "WaveNetWEPWeakCrack.h"
#import "AirCrackWrapper.h"
#import "KisMACNotifications.h"
#import "WaveWeakContainer.h"
#import "WaveHelper.h"
#import <BIGeneric/BINSExtensions.h>

#define SRET { [[WaveHelper importController] terminateWithCode: 1]; [pool release]; return; }
#define RET { [[WaveHelper importController] terminateWithCode: -1]; [pool release]; return; }
#define CHECK { if (_password != Nil) RET; if (_isWep != encryptionTypeWEP && _isWep != encryptionTypeWEP40) RET; }

@implementation WaveNet(WEPWeakCrackExtension)

- (BOOL)doWeakCrackForLen:(int)len andKeyID:(int)keyID {
	AirCrackWrapper *a = [[AirCrackWrapper alloc] init];
    
    [a setKeyLen:len];
    [a setKeyID:keyID];
    
    @synchronized (_ivData[keyID]) {
        [a setIVs:[_ivData[keyID] data]];
    }
    
    if ([a attack]) {
        NSData *d = [a key];
        const UInt8 *k = [d bytes];
        int i;
        
        _password = [[NSMutableString stringWithFormat:@"%.2X", k[0]] retain];
        for (i=1; i<len;i++)
            [(NSMutableString*)_password appendString:[NSString stringWithFormat:@":%.2X", k[i]]];
		
		[a release];
		return TRUE;
    }
    
    [a release];
	return FALSE;
} 
- (void)performCrackWEPWeakforKeyIDAndLen:(NSNumber*)keyidAndLen {
    int temp, keyID;
    enum keyLen len;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CHECK;
    
    temp = [keyidAndLen intValue];
    
    keyID = temp & 0xFF;
    NSParameterAssert(keyID <= 3 && keyID >= 0);
    len   = (temp >> 8) & 0xFFFFFF;
    NSParameterAssert(len == keyLen104bit || len == keyLen40bit || len == keyLenAll);
    
    if (!_ivData[keyID]) RET;
    if ([_ivData[keyID] count] <= 8) RET; //need at least 8 IVs
    
	if(len == keyLenAll) {
		if([self doWeakCrackForLen:keyLen40bit andKeyID:keyID]) SRET;
		if([self doWeakCrackForLen:keyLen104bit andKeyID:keyID]) SRET;
	} else {
		if([self doWeakCrackForLen:len andKeyID:keyID]) SRET;
	}
 
    RET;
}

@end
