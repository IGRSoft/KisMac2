/*
 
 File:			WavePcapDump.m
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

#import "WavePcapDump.h"
#import "WaveHelper.h"
#import "WaveDriver.h"
#import "WavePacket.h"
#import "../Core/80211b.h"

@implementation WavePcapDump

- (id) initWithDriver:(WaveDriver *)wd andDumpFilter:(int)dumpFilter {
    self = [super initWithDriver:wd];
    
    if (!self)
        return nil;

    _dumpFilter = dumpFilter;
    NSString* path;
    char err[PCAP_ERRBUF_SIZE];
    int i;
    _f = NULL;
    _p = NULL;

    NSDictionary *d = [_driver configuration];
    NSString *dumpDestination;
    dumpDestination = d[@"dumpDestination"];

    //in the example dump are informations like 802.11 network
    path = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/example.dump"];
    _p = pcap_open_offline([path UTF8String],err);
    if (_p) {
        i = 1;
        
        //opens output
        path = [[NSDate date] descriptionWithCalendarFormat:[dumpDestination stringByExpandingTildeInPath]
												   timeZone:nil
													 locale:nil];
        while ([[NSFileManager defaultManager] fileExistsAtPath: path]) 
        {
            path = [[NSString stringWithFormat:@"%@.%u", dumpDestination, i] stringByExpandingTildeInPath];
            path = [[NSDate date] descriptionWithCalendarFormat:path
													   timeZone:nil
														 locale:nil];
            ++i;
        }
        
        _f = pcap_dump_open(_p, [path UTF8String]);
    } //p
    
    //error
    if(_p == NULL || _f == NULL) {
        NSBeginAlertSheet(ERROR_TITLE, 
                          OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL, 
                          NSLocalizedString(@"Could not create dump", "LONG error description with possible causes."),
                          //@"Could not create dump file %@. Are you sure that the permissions are set correctly?" 
                          path);
        if (_p) {
            pcap_close(_p);
            _p = NULL;
        }
        return nil;
    }
    return self;
}

- (WavePluginPacketResponse) gotPacket:(WavePacket *)packet fromDriver:(WaveDriver *)driver {
    struct pcap_pkthdr h;
    
    // Dump if needed
    if ( (_dumpFilter==1) || 
        ((_dumpFilter==2) && ([packet type] == IEEE80211_TYPE_DATA)) || 
        ((_dumpFilter==3) && ([packet isResolved]!=-1)) ) {
        memcpy(&h.ts, [packet creationTime], sizeof(struct timeval));
        h.len = h.caplen = [packet length];
        pcap_dump((u_char*)_f, &h, (u_char*)[packet frame]);
    }
    
    return WavePluginPacketResponseContinue;
}

-(void) dealloc {
    if (_f)
        pcap_dump_close(_f);
    if (_p)
        pcap_close(_p);
}

@end
