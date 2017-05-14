/*
 
 File:			WaveNetEntry.h
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

#import <CoreWLAN/CoreWLAN.h>
#import "WavePacket.h"

@class WaveNet;

#define MAXNETS 1000000
#define MAXCACHE 20
#define MAXFILTER 100
#define MAXCHANGED 100

#ifdef FASTLOOKUP
    #define LOOKUPSIZE 0x1000000
#else
    #define LOOKUPSIZE 0x10000
#endif

typedef struct WaveNetEntry
{
    unsigned char ID[6];
    BOOL changed;
    __unsafe_unretained WaveNet* net;

} WaveNetEntry;

@interface WaveContainer : NSObject <NSFastEnumeration> {
    NSInteger _order;
    BOOL _dropAll;
    BOOL _ascend;
    NSLock *_sortLock;
    
    NSInteger _viewType;
    NSInteger _viewChannel;
    NSInteger _viewCrypto;
    
    NSString *_viewSSID;
    NSString *_filterString;
	NSString *_filterType;
	
    WaveNetEntry *_idList;
    NSUInteger _sortedList[MAXNETS + 1];
    NSUInteger _lookup[LOOKUPSIZE];
    
    //NSUInteger _cache[MAXCACHE + 1];
    UInt8 _filter[MAXFILTER + 1][6];
    
    NSUInteger _netCount;
    NSUInteger _sortedCount;
    NSUInteger _cacheSize;
    NSUInteger _filterCount;
    
    NSArray *_netFields;
    NSMutableArray *_displayedNetFields;
	
	NSOperationQueue *queue;
}

//for initialisation etc...
- (void)updateSettings:(NSNotification*)note;

//for loading and saving
- (BOOL)loadLegacyData:(NSDictionary *)data;
- (BOOL)loadData:(NSArray *)data;
- (BOOL)importLegacyData:(NSDictionary *)data;
- (BOOL)importData:(NSArray *)data;
- (NSArray *)dataToSave;

//for view filtering
- (void)refreshView;
- (void)setViewType:(NSInteger)type value:(id)val;
- (void)setFilterType:(NSString *)filter;
- (void)setFilterString:(NSString *)filter;
- (NSString *)getImageForChallengeResponse:(NSInteger)challengeResponseStatus;
- (NSString *)getStringForEncryptionType:(encryptionType)encryption;
- (NSString *)getStringForNetType:(networkType)type;

//for sorting
- (void)sortByColumn:(NSString *)ident order:(BOOL)ascend;
- (void)sortWithShakerByColumn:(NSString *)ident order:(BOOL)ascend;

//for adding data
- (BOOL)IDFiltered:(const UInt8 *)ID;
- (BOOL)addPacket:(WavePacket *)p liveCapture:(BOOL)live;
- (BOOL)addAppleAPIData:(CWNetwork *)net;
- (BOOL)addNetwork:(WaveNet *)net;

- (NSUInteger)count;
- (WaveNet *)netAtIndex:(NSUInteger)index;
- (WaveNet *)netForKey:(UInt8 *)ID;
- (NSMutableArray*)allNets;

- (void)scanUpdate:(NSInteger)graphLength;
- (void)ackChanges;
- (NSUInteger)nextChangedRow:(NSUInteger)lastRow;

- (void)clearAllEntries;
- (void)clearEntry:(WaveNet *)net;
- (void)clearAllBrokenEntries;

@end
