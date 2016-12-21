/*
 
 File:			WaveWeakContainer.m
 Program:		KisMAC
 Author:		Michael Roßberg
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

#import "WaveWeakContainer.h"


@implementation WaveWeakContainer

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _count = 0;
    memset(_data, 0, sizeof(_data));
    
    return self;
}

- (id)initWithData:(NSData*)data
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    [self addData:data];
    
    return self;
}

#pragma mark -

- (void)setBytes:(const UInt8*)bytes forIV:(const UInt8*)iv
{
    UInt8 *d;
    if (_data[iv[2]] == NULL)
    {
        _data[iv[2]] = malloc(sizeof(UInt8 *)*LAST_BIT);
        if(_data[iv[2]] == NULL)
        {
            DBNSLog(@"malloc failed");
            return;
        }
        memset(_data[iv[2]], 0, sizeof(UInt8 *)*LAST_BIT);
    }
    
    if ((_data[iv[2]])[iv[1]] == NULL)
	{
		(_data[iv[2]])[iv[1]] = malloc(3*sizeof(UInt8)*LAST_BIT);
		if ((_data[iv[2]])[iv[1]] == NULL) {
			DBNSLog(@"malloc failed");
			return;
		}
        memset((_data[iv[2]])[iv[1]], 0, 3*sizeof(UInt8)*LAST_BIT);
    }
    
    d = &((_data[iv[2]])[iv[1]])[iv[0] * 3];
    d[1] = bytes[0];
    d[2] = bytes[1];
    
    if (d[0] == 0)
    {
        d[0] = 1;
        ++_count;
    } 
}

- (NSUInteger) count
{
    return _count;
}

- (void)addData:(NSData*)data
{
    if (!data)
    {
        return;
    }
    NSParameterAssert([data length] % 5 == 0);
    
    const UInt8 *d = [data bytes];
    
    for (NSUInteger i = 0; i  < [data length]; i+=5)
    {
        [self setBytes:&d[i+3] forIV:&d[i]];
    }
}

- (NSData*)data
{
    UInt8 *d, *m;
    NSInteger x, y, z;
    
    d = malloc(_count * 5);
    m = d;
    
    for(x = 0; x < LAST_BIT; ++x)
    {
        if (_data[x] != nil)
        {
            for (y = 0; y < LAST_BIT; ++y)
            {
                if ((_data[x])[y] != nil)
                {
                    for (z = 0; z < (LAST_BIT * 3); z+=3)
                    {
                        if (((_data[x])[y])[z] != 0)
                        {
                            m[0] = (z / 3) & 0xFF;
                            m[1] = y & 0xFF;
                            m[2] = x & 0xFF;
                            m[3] = (((_data[x])[y])[z+1]) & 0xFF;
                            m[4] = (((_data[x])[y])[z+2]) & 0xFF;
                            m += 5;
                        }
                    }
                }
            }
        }
    }
    
    NSData *data = [NSData dataWithBytes:d length:_count * 5];
    free(d);
    
    return data;
}


#pragma mark -

- (void) dealloc
{
    NSInteger x, y;
    
    for(x = 0; x < LAST_BIT; ++x)
    {
        if (_data[x] != nil)
        {
            for (y = 0; y < LAST_BIT; ++y)
            {
                if ((_data[x])[y] != nil)
                {
                    free((_data[x])[y]);
                }
            }
            
            free(_data[x]);
        }
    }
}

@end
