/*
 
 File:			WaveNetEntry.m
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

#import "WaveContainer.h"
#import "WaveHelper.h"
#import "KisMACNotifications.h"
#import "WaveNet.h"

//TODO make _idList binary search compatible 
// AVL trees?!
// hash - ring - structure?

typedef struct WaveSort {
    NSInteger ascend;
    NSUInteger *sortedList;
    WaveNetEntry *idList;
} WaveSort;

UInt32 hashForMAC(const UInt8* val) {
    UInt32 l, j, k;
#if BYTE_ORDER == BIG_ENDIAN
    //add to hash table
#ifdef FASTLOOKUP
    memcpy(((char*)&l)+1, val, 3);
    memcpy(((char*)&j)+1, val+3, 3);
    l = (l ^ j) & 0x00FFFFFF; 
#else
    memcpy(((char*)&l)+2, val,   2);
    memcpy(((char*)&j)+2, val+2, 2);
    memcpy(((char*)&k)+2, val+4, 2);
    l = (l ^ j ^ k) & 0x0000FFFF;
#endif
    
#else
#ifdef FASTLOOKUP
    memcpy(((char*)&l), val, 3);
    memcpy(((char*)&j), val+3, 3);
    l = (l ^ j) & 0x00FFFFFF; 
#else
    memcpy(((char*)&l), val,   2);
    memcpy(((char*)&j), val+2, 2);
    memcpy(((char*)&k), val+4, 2);
    l = (l ^ j ^ k) & 0x0000FFFF;
#endif
#endif
    return l;
}

@implementation WaveContainer

- (id)init
{
    NSInteger i;
    self = [super init];
    if (!self) return nil;
    
    //todo fixme!! we should not allocate a fixed list
    _idList = malloc(sizeof(WaveNetEntry) * MAXNETS);
    if(!_idList) return nil;
    
    _order = -1;
    _dropAll = NO;
    
    _viewType =  0;
    _netCount = 0;
    _filterCount = 0;
    _cacheSize = 0;
    _viewCrypto = 0;
    
    _sortLock = [[NSLock alloc] init];
    
    for( i = 0 ; i < LOOKUPSIZE ; ++i)
		_lookup[i]=LOOKUPSIZE;
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateSettings:)
												 name:KisMACFiltersChanged object:nil];
    [self updateSettings:nil];
	
	queue = [[NSOperationQueue alloc] init];
    
    return self;
}

#pragma mark -

- (void)updateSettings:(NSNotification*)note
{
    NSArray *filtered;
    NSUInteger i, j, tmp[6];
    NSUserDefaults *sets = [NSUserDefaults standardUserDefaults];
    
    filtered = [sets objectForKey:@"FilterBSSIDList"];
    
    _filterCount = 0;
    for( i = 0 ; i < [filtered count] ; ++i)
	{
        if (sscanf([[filtered objectAtIndex:i] UTF8String],"%2lX%2lX%2lX%2lX%2lX%2lX", &tmp[0], &tmp[1], &tmp[2], &tmp[3], &tmp[4], &tmp[5]) != 6)
			continue;
    
        for ( j = 0 ; j < 6 ; ++j)
            _filter[i][j] = tmp[j];
        
        ++_filterCount;
    }
}


#pragma mark -

- (void) addNetToView:(NSUInteger)entry
{
    BOOL add = NO;
    
    switch (_viewType) {
    case 0:
        add = YES;
        break;
    case 1:
        add = ([_idList[entry].net packetsPerChannel][_viewChannel]!=0);
        break;
    case 2:
        add = ([[_idList[entry].net SSID] isEqualToString:_viewSSID]);
        break;
    case 3:
        add = ([_idList[entry].net wep] == _viewCrypto);
        break;
    default:
        DBNSLog(@"invalid view. this is a bug and shall never happen\n");
    }
    
	/*if (entry > 0) {
		@synchronized(_idList[entry].net)
		{
			[self checkEntry:_idList[entry].net];
		}
	}*/
	
	// switch type here
	if ( [_filterType isEqualToString:@"SSID"] )
	{
		if (add
			&& ((_filterString == nil || [[_idList[entry].net SSID] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	} else if ( [_filterType isEqualToString:@"BSSID"] )
	{
		if (add
			&& ((_filterString == nil || [[_idList[entry].net BSSID] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	} else if ( [_filterType isEqualToString:@"Vendor"])
	{
		if (add
			&& ((_filterString == nil || [[_idList[entry].net getVendor] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	} else if ( [_filterType isEqualToString:@"Encryption"])
	{
		if (add
			&& ((_filterString == nil || ( [[self getStringForEncryptionType:[_idList[entry].net wep]] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location) != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	} else if ( [_filterType isEqualToString:@"Main Channel"])
	{
		if (add
			&& ((_filterString == nil || ( [[NSString stringWithFormat:@"%@", @([_idList[entry].net originalChannel])] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location) != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else {
			[_idList[entry].net setVisible: NO];
		}
	} else if ( [_filterType isEqualToString:@"Comment"])
	{
		if (add
			&& ((_filterString == nil || ( [[_idList[entry].net comment] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location) != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	} else if ( [_filterType isEqualToString:@"Type"])
	{
		if (add
			&& ((_filterString == nil || ( [[self getStringForNetType:[_idList[entry].net type]] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location) != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	} else
	{
		_filterType = @"SSID";
		if (add
			&& ((_filterString == nil || [[_idList[entry].net SSID] rangeOfString:_filterString options:NSCaseInsensitiveSearch].location != NSNotFound))
			&& [_idList[entry].net isCorrectSSID])
		{
			_sortedList[_sortedCount] = entry;
			++_sortedCount;
			[_idList[entry].net setVisible: YES];
		}
		else
		{
			[_idList[entry].net setVisible: NO];
		}
	}
}

- (NSString*) getImageForChallengeResponse:(NSInteger)challengeResponseStatus
{
    switch (challengeResponseStatus) {
        case chreResponse:
        case chreChallenge:
            return @"orangegem";
        case chreComplete:
            return @"greengem";
        case chreNone:
        default:
            return @"redgem";
    }
}

- (NSString*) getStringForEncryptionType:(encryptionType)encryption
{
	switch(encryption) {
		case encryptionTypeNone: 
			return @"NO";
		case encryptionTypeWEP:
			return @"WEP";
		case encryptionTypeWEP40:
			return @"WEP-40";
		case encryptionTypeWPA:
			return @"WPA";
		case encryptionTypeWPA2:
			return @"WPA2";
		default:
			return @"Unknown";
	}
}

- (NSString*) getStringForNetType:(networkType)type
{
	switch (type) {
		case networkTypeUnknown:
			return @"Unknown";
		case networkTypeAdHoc:
			return @"ad-hoc";
		case networkTypeManaged:
			return @"managed";
		case networkTypeTunnel:
			return @"tunnel";
		case networkTypeProbe:
			return @"probe";
		case networkTypeLucentTunnel:
			return @"lucent tunnel";
		default:
			return @"Unknown";
			DBNSLog(@"Invalid net type %@, WTF?", @(type));
	}
}

- (void) refreshView
{
    NSUInteger i;
    
    _sortedCount = 0;
    for ( i = 0 ; i < _netCount ; ++i)
        [self addNetToView:i];
}

- (void) setViewType:(NSInteger)type value:(id)val
{
    _viewType = type;
    
    switch(_viewType) {
    case 0:
        break;
    case 1:
        _viewChannel = [val intValue];
        break;
    case 2:
		_viewSSID = val;
        break;
    case 3:
        _viewCrypto = [val intValue];
        break;
    default:
        DBNSLog(@"invalid viewtype. this is a bug and shall never happen!\n");
    }
    [self refreshView];
}

- (void) setFilterString:(NSString*)filter
{
    if ([filter length] == 0)
		_filterString = nil;
    else
		_filterString = filter;
    
    [self refreshView];    
}

- (void) setFilterType:(NSString*)filter
{
	_filterString = filter;
    [self refreshView];    
}

#pragma mark -

- (BOOL) addNetwork:(WaveNet*)net
{
    NSUInteger entry, l;
    
	NSParameterAssert(net);
	
    if (_netCount >= MAXNETS)
		return NO;
    
    ++_netCount;
    entry = _netCount - 1;
    memcpy(&_idList[entry].ID, [net rawID], 6);
    _idList[entry].net = net;
    
    //add to hash table
    l = hashForMAC(_idList[entry].ID);
    
    while (_lookup[l]!=LOOKUPSIZE) {
        l = (l + 1) % LOOKUPSIZE;
    }
    _lookup[l] = entry;
    
    [self addNetToView:entry];
    
    return YES;
}

- (BOOL) loadLegacyData:(NSDictionary*)data
{
    NSEnumerator *e;
    id n;
    WaveNet *net;
        
    e = [data objectEnumerator];
    while ((n = [e nextObject])) {
        if (![n isMemberOfClass:[WaveNet class]]) {
            DBNSLog(@"Could not load legacy data, because it is bad!");
            return NO;
        }
        
        if (_netCount == MAXNETS) {
            DBNSLog(@"Loaded more networks, but could not add them since you reached MAXNETS. Please recompile with a higher value");
            return YES;
        }
        
        net = n;
        
        [self addNetwork:net];
    }
    
    return YES;
}

- (BOOL) loadData:(NSArray*)data
{
    id n = nil;
    NSInteger i = 0;
    WaveNet *net = nil;
     
    for ( i = 0 ; i < [data count] ; ++i)
	{
        n = [data objectAtIndex:i];
        if (![n isMemberOfClass:[WaveNet class]])
		{
			if (![n isKindOfClass:[NSDictionary class]])
			{
				DBNSLog(@"Could not load data, because it is bad!");
				return NO;
			}
			n = [[WaveNet alloc] initWithDataDictionary:n];
			if (!n)
				continue;
        }
        
        if (_netCount == MAXNETS)
		{
            DBNSLog(@"Loaded more networks, but could not add them since you reached MAXNETS. Please recompile with a higher value");
            return YES;
        }
        
        CFRetain((__bridge CFTypeRef)(n));
        net = [n copy];
        CFRelease((__bridge CFTypeRef)(n));
		
        [self addNetwork:net];
    }
    
    return YES;
}

- (BOOL) importLegacyData:(NSDictionary*)data
{
    NSEnumerator *e;
    id n;
    WaveNet *net;
    NSInteger i,  maxID = 0;
    
    for(i = 0 ; i < _netCount ; ++i)
        if ([_idList[i].net netID] > maxID) maxID = [_idList[i].net netID];

    e = [data objectEnumerator];
    while ((n = [e nextObject]))
	{
        if (![n isMemberOfClass:[WaveNet class]])
		{
            DBNSLog(@"Could not load legacy data, because it is bad!");
            return NO;
        }
        
        if (_netCount == MAXNETS) {
            DBNSLog(@"Loaded more networks, but could not add them since you reached MAXNETS. Please recompile with a higher value");
            return YES;
        }
        
        net = [self netForKey:[n rawID]];
        
        if (!net)
		{
            [self addNetwork:n];
            [n setNetID:++maxID];
        }
		else
			[net mergeWithNet:n];
    }
    
    return YES;
}

- (BOOL) importData:(NSArray*)data
{
    id n;
    NSInteger i, maxID = 0;
    WaveNet *net = nil;
    
    for(i = 0; i < _netCount; ++i)
        if ([_idList[i].net netID] > maxID) maxID = [_idList[i].net netID];
    
    for ( i = 0 ; i < [data count] ; ++i)
	{
        n = [data objectAtIndex:i];
        if (![n isMemberOfClass:[WaveNet class]])
		{
			if (![n isMemberOfClass:[NSDictionary class]])
			{
				DBNSLog(@"Could not load data, because it is bad!");
				return NO;
			}
			n = [[WaveNet alloc] initWithDataDictionary:n];
        }
        
        [n setNetID:0];
        
        if (_netCount == MAXNETS)
		{
            DBNSLog(@"Loaded more networks, but could not add them since you reached MAXNETS. Please recompile with a higher value");
            return YES;
        }
        
        net = [self netForKey:[n rawID]];
        
        if (!net) 
        {
            [self addNetwork:n];
            [n setNetID:++maxID];
        }
		else
			[net mergeWithNet:n];
    }

    return YES;
}

- (NSArray*) dataToSave
{
    NSMutableArray *a;
    NSUInteger i;
    
    a = [NSMutableArray arrayWithCapacity:_netCount];
    for ( i = 0 ; i < _netCount ; ++i)
        [a addObject:[_idList[i].net dataDictionary]];

    return a;
}

#pragma mark -


NSInteger compValues(NSInteger v1, NSInteger v2)
{
    if (v1 < v2) return NSOrderedAscending;
    else if (v1 > v2) return NSOrderedDescending;
    else return NSOrderedSame;
}

NSInteger channelSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net channel];
    NSInteger v2 = [(*p).idList[*index2].net channel];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger primaryChannelSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net originalChannel];
    NSInteger v2 = [(*p).idList[*index2].net originalChannel];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger idSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net netID];
    NSInteger v2 = [(*p).idList[*index2].net netID];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger bssidSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSString *d1 = [(*p).idList[*index1].net BSSID];
    NSString *d2 = [(*p).idList[*index2].net BSSID];
    return (*p).ascend * [d1 compare:d2 options:NSLiteralSearch];
}

NSInteger ssidSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger i;
    NSString *d1 = [(*p).idList[*index1].net SSID];
    NSString *d2 = [(*p).idList[*index2].net SSID];
    i =  [d1 compare:d2 options:NSLiteralSearch|NSCaseInsensitiveSearch];
    return (*p).ascend * i;
}

NSInteger wepSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net wep];
    NSInteger v2 = [(*p).idList[*index2].net wep];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger typeSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net type];
    NSInteger v2 = [(*p).idList[*index2].net type];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger signalSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net curSignal];
    NSInteger v2 = [(*p).idList[*index2].net curSignal];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger maxSignalSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net maxSignal];
    NSInteger v2 = [(*p).idList[*index2].net maxSignal];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger avgSignalSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net avgSignal];
    NSInteger v2 = [(*p).idList[*index2].net avgSignal];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger packetsSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSInteger v1 = [(*p).idList[*index1].net packets];
    NSInteger v2 = [(*p).idList[*index2].net packets];
    return (*p).ascend * compValues(v1,v2);
}

NSInteger dataSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    CGFloat v1 = [(*p).idList[*index1].net dataCount];
    CGFloat v2 = [(*p).idList[*index2].net dataCount];
    if (v1 < v2) return (*p).ascend * NSOrderedAscending;
    else if (v1 > v2) return (*p).ascend * NSOrderedDescending;
    else return NSOrderedSame;
}

NSInteger lastSeenSort(WaveSort* p, const NSInteger *index1, const NSInteger *index2)
{
    NSDate *d1 = [(*p).idList[*index1].net lastSeenDate];
    NSDate *d2 = [(*p).idList[*index2].net lastSeenDate];
    return (*p).ascend * [d1 compare:d2];
}

typedef int (*SORTFUNC)(void *, const void *, const void *);

- (void) sortByColumn:(NSString*)ident order:(BOOL)ascend
{
	[queue addOperationWithBlock:^{
		WaveSort ws;
		
		if (![_sortLock tryLock]) return;
		
		_ascend = ascend;
		ws.ascend = ascend ? 1 : -1;
		ws.idList = _idList;
		
		if ([ident isEqualToString:@"channel"])				qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)channelSort);
		else if ([ident isEqualToString:@"primaryChannel"])	qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)primaryChannelSort);
		else if ([ident isEqualToString:@"id"])				qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)idSort);
		else if ([ident isEqualToString:@"bssid"])			qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)bssidSort);
		else if ([ident isEqualToString:@"ssid"])			qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)ssidSort);
		else if ([ident isEqualToString:@"wep"])			qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)wepSort);
		else if ([ident isEqualToString:@"type"])			qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)typeSort);
		else if ([ident isEqualToString:@"signal"])			qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)signalSort);
		else if ([ident isEqualToString:@"maxsignal"])		qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)maxSignalSort);
		else if ([ident isEqualToString:@"avgsignal"])		qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)avgSignalSort);
		else if ([ident isEqualToString:@"packets"])		qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)packetsSort);
		else if ([ident isEqualToString:@"data"])			qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)dataSort);
		else if ([ident isEqualToString:@"lastseen"])		qsort_r(_sortedList, _sortedCount, sizeof(NSUInteger), &ws, (SORTFUNC)lastSeenSort);
		
		else DBNSLog(@"Unknown sorting column. This is a bug and should never happen.");
		
		[_sortLock unlock];
	}];
}

- (void)sortWithShakerByColumn:(NSString *)ident order:(BOOL)ascend
{
	
	[queue addOperationWithBlock:^{

		SORTFUNC func;
		BOOL sorted = YES;
		NSInteger ret;
		NSUInteger w, x, y, z;
		WaveSort ws;
		
		if (![_sortLock tryLock]) return;
		
		_ascend = ascend;
		ws.ascend = ascend ? 1 : -1;
		ws.idList = _idList;
		ws.sortedList = _sortedList;
		
		if ([ident isEqualToString:@"channel"])				func = (SORTFUNC)channelSort;
		else if ([ident isEqualToString:@"primaryChannel"]) func = (SORTFUNC)primaryChannelSort;
		else if ([ident isEqualToString:@"id"])				func = (SORTFUNC)idSort;
		else if ([ident isEqualToString:@"bssid"])			func = (SORTFUNC)bssidSort;
		else if ([ident isEqualToString:@"ssid"])			func = (SORTFUNC)ssidSort;
		else if ([ident isEqualToString:@"wep"])			func = (SORTFUNC)wepSort;
		else if ([ident isEqualToString:@"type"])			func = (SORTFUNC)typeSort;
		else if ([ident isEqualToString:@"signal"])			func = (SORTFUNC)signalSort;
		else if ([ident isEqualToString:@"maxsignal"])		func = (SORTFUNC)maxSignalSort;
		else if ([ident isEqualToString:@"avgsignal"])		func = (SORTFUNC)avgSignalSort;
		else if ([ident isEqualToString:@"packets"])		func = (SORTFUNC)packetsSort;
		else if ([ident isEqualToString:@"data"])			func = (SORTFUNC)dataSort;
		else if ([ident isEqualToString:@"lastseen"])		func = (SORTFUNC)lastSeenSort;
		else
		{
			[_sortLock unlock];
			DBNSLog(@"Unknown sorting column. This is a bug and should never happen.");
			return;
		}
		
		for (y = 1 ; y <= _sortedCount ; ++y) {
			
			for (x = y - 1; x < (_sortedCount - y); ++x)
			{
				w = x + 1;
				ret = (*func)(&ws, &_sortedList[x], &_sortedList[w]);
				if (ret == NSOrderedDescending) {
					sorted = NO;
					
					//switch places
					z = _sortedList[x];
					_sortedList[x] = _sortedList[w];
					_sortedList[w] = z;
					
					_idList[_sortedList[x]].changed = YES;
					_idList[_sortedList[w]].changed = YES;
				}
			}
			
			if (sorted)
				break;
			
			sorted = YES;
			
			for (x = (_sortedCount - y) ; x >= y ; x--) {
				w = x - 1;
				ret = (*func)(&ws, &_sortedList[w], &_sortedList[x]);
				if (ret == NSOrderedDescending)
				{
					sorted = NO;
					
					//switch places
					z = _sortedList[x];
					_sortedList[x] = _sortedList[w];
					_sortedList[w] = z;
					
					_idList[_sortedList[x]].changed = YES;
					_idList[_sortedList[w]].changed = YES;
				}
			}
			
			if (sorted) break;
			sorted = YES;
		}
		
		[_sortLock unlock];
	}];
}

#pragma mark -

- (BOOL)IDFiltered:(const UInt8 *)ID
{
	NSUInteger i;
	
	for ( i = 0 ; i < _filterCount ; ++i)
		if (memcmp(ID, _filter[i], 6)==0)
			return YES;
	
	return NO;
}

- (NSUInteger) findNetwork:(const UInt8 *)ID
{
    NSUInteger i, lentry;
    NSUInteger entry = BAD_ADDRESS;
    NSUInteger l = 0;
    
    
    //see if it is filtered
    if ([self IDFiltered:ID])
    {
		return BAD_ADDRESS;
    }
    
    //lookup the net in the hashtable
    l = hashForMAC(ID);
    lentry = l;
    
    i = _lookup[l];
    while (i!=LOOKUPSIZE)
	{
        if (memcmp(ID, _idList[i].ID, 6) == 0)
        {
            entry = i;
            break;
        }
        
        l = (l + 1) % LOOKUPSIZE;
        i = _lookup[l];
    }
            
    if (entry == BAD_ADDRESS)
	{
        //the net does not exist - add it
        
        if (_netCount == MAXNETS)
		{
            DBNSLog(@"Found network, but could not add it since you reached MAXNETS. Please recompile with a higher value");
            return BAD_ADDRESS;
        }
        
        ++_netCount;
        entry = _netCount - 1;
        memcpy(&_idList[entry].ID, ID, 6);
        
        @autoreleasepool
        {
            WaveNet *net = [[WaveNet alloc] initWithID:entry];
            if ([[net SSID] isEqualToString:@"<no ssid>"])
            {
                _idList[entry].net = net;
                CFRetain((__bridge CFTypeRef)(_idList[entry].net));
                _lookup[l] = entry;
                
                [self addNetToView:entry];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:KisMACNetworkAdded object:self];
            }
            else
            {
                DBNSLog(@"Incorrect network");
            }
        }
    }
    
    if (l != lentry)
	{
        //optimize the hash table...
        i = _lookup[lentry];
        _lookup[lentry] = _lookup[l];
        _lookup[l] = i;
    }

    return entry;
}

- (BOOL)addPacket:(WavePacket*)p liveCapture:(BOOL)live
{
    NSUInteger entry;
    UInt8  ID[6];
    
    if (_dropAll)
		return YES;
    
	if (![p ID:ID])
		return YES;
    
    entry = [self findNetwork:ID];
    
    if (entry == BAD_ADDRESS)
    {
		return NO;                          //the object is filtered...
    }
    
    @synchronized(_idList[entry].net)
    {
		[_idList[entry].net parsePacket:p withSound:live];		//add the packet to the network
		_idList[entry].changed = YES;
    }
	
    return YES;
}

- (BOOL) addAppleAPIData:(CWNetwork*)net 
{
    NSUInteger entry = 0;
	NSParameterAssert(net);

    if (_dropAll) return YES;
    
	UInt8  macData[6] = {0};
	
	// [CWInterface bssid] returns a string formatted "00:00:00:00:00:00".
	NSString* macString = [net bssid];
	if (macString && ([macString length] == 17))
	{
		for (NSUInteger i = 0; i < 6; ++i)
		{
			NSString* part = [macString substringWithRange:NSMakeRange(i * 3, 2)];
			NSScanner* scanner = [NSScanner scannerWithString:part];
			unsigned data = 0;
			if (![scanner scanHexInt:&data])
			{
				data = 0;
			}
			macData[i] = (NSUInteger ) data;
		}
	}
	
    entry = [self findNetwork: macData];
    if (entry == BAD_ADDRESS) return NO;                          //the object is filtered...
    
	@synchronized(_idList[entry].net)
    {
		[_idList[entry].net parseAppleAPIData:net];             //add the data to the network
    }
	_idList[entry].changed = YES;
    
    return YES;
}

#pragma mark -

- (NSUInteger) count
{
    return _sortedCount;
}

- (WaveNet *) netAtIndex:(NSUInteger)index
{
    if (index >= _sortedCount)
		return 0;
	
    return _idList[_sortedList[index]].net;
}

- (WaveNet*) netForKey:(UInt8 *) ID
{
    unsigned long i, l, entry = LOOKUPSIZE;
    
    //lookup the net in the hashtable
    l = hashForMAC(ID);
    
    i=_lookup[l];
    while (i!=LOOKUPSIZE)
	{
        if (memcmp(ID, _idList[i].ID, 6)==0)
		{
			entry = i;
			break;
        }
        l = (l + 1) % LOOKUPSIZE;
        i=_lookup[l];
    }
    
    if (entry==LOOKUPSIZE)
		return nil;
    
    return _idList[entry].net;
}

- (NSMutableArray*) allNets
{
    NSMutableArray *a;
    NSUInteger i;
    
    a = [NSMutableArray array];
    for ( i = 0; i < _sortedCount ; ++i)
	{
		WaveNet *w = _idList[_sortedList[i]].net;
		if (w) {
			[a addObject:w];
		}
    }
	
    return a;
}

- (void) scanUpdate:(NSInteger)graphLength
{
    NSUInteger i;

	for(i = 0 ; i < _netCount ; ++i)
    {
		WaveNet *w = _idList[i].net;
		@synchronized(w)
		{
			if ([w noteFinishedSweep:graphLength])
            {
				//make sure this is going to be updated
				_idList[i].changed = YES;
			}
		}
	}
}

- (void) ackChanges
{
    NSUInteger i;
    for(i = 0 ; i < _netCount ; ++i) _idList[i].changed = NO;
}

- (NSUInteger) nextChangedRow:(NSUInteger)lastRow
{
    NSUInteger nxt;
    
    if (lastRow == BAD_ADDRESS)
		nxt=0;
    else
		nxt = lastRow + 1;
    
    while (nxt < _sortedCount)
	{
        if (_idList[_sortedList[nxt]].changed)
		{
			if ([_idList[_sortedList[nxt]].net isCorrectSSID]) {
				return nxt;
			}
		}
        ++nxt;
    }

    return BAD_ADDRESS;
}
#pragma mark -

- (void) clearAllEntries
{
    NSInteger i, oldcount;
    WaveNet *e;
    
    _dropAll = YES;
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    oldcount = _netCount;
    for ( i = 0 ; i < LOOKUPSIZE ; ++i )
		_lookup[i]=LOOKUPSIZE;
    
	_sortedCount = 0;
    _netCount = 0;

    for ( i = 0 ; i < oldcount ; ++i )
	{
        e = _idList[i].net;
        _idList[i].net = nil;
        CFRelease((__bridge CFTypeRef)(e));
    }
    
    _dropAll = NO;
}

- (void) checkEntry:(WaveNet*)net
{
	if ([[net SSID] isEqualToString:@"<no ssid>"])
		[self clearEntry:net];
}

- (void) clearEntry:(WaveNet*)net
{
	if (!net) {
		return;
	}
	
    UInt8  *ID = [net rawID];
    NSUInteger i, l, entry = LOOKUPSIZE;
	WaveNet* n;
    
	//make sure no one messes with us
    _dropAll = YES;
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
	n = net;
    CFRelease((__bridge CFTypeRef)(n));
	
    for( i = 0 ; i < LOOKUPSIZE; ++i )
    {
        _lookup[i] = LOOKUPSIZE;
    }
        
    //find the entry in the sorted list
    for ( i = 0 ; i < _sortedCount ; ++i )
    {
		entry = _sortedList[i];
		if (memcmp(ID, _idList[entry].ID, 6)==0) break;
    }
    //if the entry exists in the sorted list move all sorted items one down...
    if(i < _sortedCount)
    {
        _sortedCount--;
        for (;i < _sortedCount; ++i)
            _sortedList[i] = _sortedList[i+1];
    }
    
    _netCount--;
    
    //move down from the whole list
    for ( i = entry ; i < _netCount ; ++i)
    {
        _idList[i] = _idList[i+1];
    }
    
    //if it was not the last item in the list eradicate the one before
    if (entry != i)
		_idList[i+1].net = nil;
    else
		_idList[entry].net = nil;
    
    for ( i = 0 ; i < _netCount ; ++i )
    {
        //add to hash table
        l = hashForMAC(_idList[i].ID);
        
        while (_lookup[l]!=LOOKUPSIZE)
        {
            l = (l + 1) % LOOKUPSIZE;
        }
        _lookup[l] = i;
    }

    //enable capture engine again
    _dropAll = NO;
}

- (void) clearAllBrokenEntries
{
	NSInteger i, oldcount;
    WaveNet *e;
    
    oldcount = _netCount;
	
    for ( i = 0 ; i < oldcount ; ++i)
	{
        e = _idList[i].net;
        if (![e isCorrectSSID])
		{
			[self clearEntry:e];
		}
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self clearAllEntries];
	
	[queue cancelAllOperations];
}

- (NSArray *)netFields
{
    return _netFields;
}

- (NSMutableArray *)displayedNetFields
{
    return _displayedNetFields;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [_netFields count];
}

@end
