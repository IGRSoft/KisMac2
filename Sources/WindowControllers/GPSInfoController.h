/*
 
 File:			GPSInfoController.h
 Program:		KisMAC
 Author:		themacuser  themacuser -at- gmail.com
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

@class GPSSatInfo;

@interface GPSInfoController : NSWindowController <NSWindowDelegate>
{
	NSMenuItem* _showMenu;
	IBOutlet NSLevelIndicator* _hdop_indicator;
	IBOutlet NSLevelIndicator* _fix_indicator;
	IBOutlet NSTextField* _fix_type;
	IBOutlet NSTextField* _lat_field;
	IBOutlet NSTextField* _lon_field;
	IBOutlet NSTextField* _vel_field;
	IBOutlet NSTextField* _alt_field;
	IBOutlet NSPopUpButton* _speedType;
	IBOutlet NSPopUpButton* _altType;
	IBOutlet NSProgressIndicator* _speedBar;
	IBOutlet NSProgressIndicator* _altBar;
	IBOutlet NSTextField* _hdop_field;
	IBOutlet GPSSatInfo* _satinfo;
	
	CGFloat _vel;
	CGFloat _velFactor;
	CGFloat _maxvel;
	
	CGFloat _alt;
	CGFloat _altFactor;
	CGFloat _maxalt;
	
	NSInteger _haveFix;
}
- (void)setShowMenu:(NSMenuItem *)menu;
- (void)updateDataNS:(double)ns EW:(double)ew ELV:(double)elv numSats:(NSInteger)sats HDOP:(double)hdop VEL:(CGFloat)vel;
- (IBAction)updateSpeed:(id)sender;
- (IBAction)updateAlt:(id)sender;
- (IBAction)resetPeak:(id)sender;
- (void)updateSatPRNForSat:(NSInteger)sat prn:(NSInteger)prn;
- (void)updateSatSignalStrength:(NSInteger)sat signal:(NSInteger)signal;
- (void)updateSatUsed:(NSInteger)sat used:(NSInteger)used;
@end
