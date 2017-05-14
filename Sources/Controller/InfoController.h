/*
 
 File:			InfoController.h
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

@class WaveNet;

@interface InfoController : NSObject
{
    BOOL aDetailsPane;
    BOOL _ascending;
    NSUInteger  _clientCount;
    
    WaveNet* _n;
    NSArray *aClientKeys;
    NSDictionary *aClients;
    NSString *_lastSorted;
	NSString* selectedRow;
    
    IBOutlet NSTableView* aShortTable;
    IBOutlet NSTableView* aTable;
    IBOutlet NSTableView* aClientTable;
    IBOutlet NSTextField* _commentField;
}

- (void)setDetails:(BOOL)visible;
- (IBAction)showNet:(id)sender;
- (IBAction)commentChanged:(id)sender;
- (void)reloadData;
- (NSString *) theRow;
@end
