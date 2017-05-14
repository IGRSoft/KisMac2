/*
 
 File:			TrafficController.h
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
@class WaveScanner;
@class BIGLView;
@class BIGLLineView;
@class BIGLTextView;
@class BIGLImageView;

@interface TrafficController : NSObject {
    IBOutlet BIGLView       *_view;
    IBOutlet WaveScanner    *_scanner;
    IBOutlet WaveContainer  *_container;
    IBOutlet NSPopUpButton  *_intervalButton;
    IBOutlet NSPopUpButton  *_modeButton;
    
    NSMutableArray          *_graphs;
    
    BIGLLineView            *_grid, *_gridFrame;
    BIGLTextView            *_zeroLabel, *_maxLabel, *_curLabel;
    BIGLImageView           *_legend;
    
    NSLock* zoomLock;

    NSColor *_backgroundColor;

    NSRect graphRect;
    NSTimeInterval scanInterval;
    CGFloat vScale;	// used for the vertical scaling of the graph
    CGFloat dvScale;	// used for the sweet 'zoom' in/out
    CGFloat stepx;	// step for horizontal lines on grid
    CGFloat stepy;	// step for vertical lines on grid
    CGFloat aMaximum;	// maximum bytes received
    NSInteger buffer[MAX_YIELD_SIZE];
    BOOL gridNeedsRedrawn;

    BOOL justSwitchedDataType;
    NSInteger _legendMode;
    NSInteger length;
    NSInteger offset;
    NSInteger maxLength;
    NSInteger currentMode;
    NSMutableArray* allNets;
    NSArray* colorArray;    
}

- (void)updateSettings:(NSNotification*)note;
- (void)outputTIFFTo:(NSString*)file;

- (IBAction)setTimeLength:(id)sender;
- (IBAction)setCurrentMode:(id)sender;

- (void)setBackgroundColor:(NSColor *)newColor;
- (void)setGridColor:(NSColor *)newColor;

- (void)updateGraph;
- (void)updateDataForRect:(NSRect)rect;
- (void)drawGraphInRect:(NSRect)rect;
- (void)drawGridInRect:(NSRect)rect;
- (void)drawGridLabelForRect:(NSRect)rect;
- (void)drawLegendForRect:(NSRect)rect;

- (NSString*)stringForNetwork:(WaveNet*)net;
- (NSString*)stringForBytes:(NSInteger)bytes;
- (NSString*)stringForPackets:(NSInteger)bytes;
- (NSString*)stringForSignal:(NSInteger)bytes;

@end

