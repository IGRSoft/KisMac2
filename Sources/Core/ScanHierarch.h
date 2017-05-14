/*
 
 File:			ScanHierarch.h
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
@class WaveContainer;

// this the responsible structure for the tree view. very ugly and dirty
@interface ScanHierarch : NSObject
{
    WaveContainer *_container;
    NSString *aNameString;
    NSString *aIdentKey;
    NSInteger aType;
    ScanHierarch *parent;
    NSMutableArray *children;
}

+ (ScanHierarch *) rootItem:(WaveContainer*)container index:(NSInteger)idx;
+ (void) updateTree;
+ (void) clearAllItems;

+ (void) setContainer:(WaveContainer*)container;

- (NSComparisonResult)compare:(ScanHierarch *)aHier;
- (NSComparisonResult)caseInsensitiveCompare:(ScanHierarch *)aHier;
- (NSInteger)numberOfChildren;			// Returns -1 for leaf nodes
- (ScanHierarch *)childAtIndex:(NSInteger)n;		// Invalid to call on leaf nodes
- (NSInteger)type;
- (NSString *)nameString;
- (NSString *)identKey;
@end
