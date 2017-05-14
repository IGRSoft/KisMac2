/*
 
 File:			GPSSatInfo.h
 Program:		KisMAC
 Author:		Geordie  themacuser -at- gmail.com
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

@interface GPSSatInfo : NSView
{
	NSInteger sat1_strength;
	NSInteger sat1_used;
	NSInteger sat1_prn;

	NSInteger sat2_strength;
	NSInteger sat2_used;
	NSInteger sat2_prn;

	NSInteger sat3_strength;
	NSInteger sat3_used;
	NSInteger sat3_prn;

	NSInteger sat4_strength;
	NSInteger sat4_used;
	NSInteger sat4_prn;

	NSInteger sat5_strength;
	NSInteger sat5_used;
	NSInteger sat5_prn;

	NSInteger sat6_strength;
	NSInteger sat6_used;
	NSInteger sat6_prn;

	NSInteger sat7_strength;
	NSInteger sat7_used;
	NSInteger sat7_prn;

	NSInteger sat8_strength;
	NSInteger sat8_used;
	NSInteger sat8_prn;

	NSInteger sat9_strength;
	NSInteger sat9_used;
	NSInteger sat9_prn;

	NSInteger sat10_strength;
	NSInteger sat10_used;
	NSInteger sat10_prn;

	NSInteger sat11_strength;
	NSInteger sat11_used;
	NSInteger sat11_prn;

	NSInteger sat12_strength;
	NSInteger sat12_used;
	NSInteger sat12_prn;
	
	NSDictionary *attr;
}

- (id)initWithFrame:(NSRect)frame;
- (void)drawRect:(NSRect)rect;
- (NSInteger)getPRNForSat:(NSInteger)sat;
- (void)setPRNForSat:(NSInteger)sat PRN:(NSInteger)prn;
- (NSInteger)getUsedForSat:(NSInteger)sat;
- (void)setUsedForSat:(NSInteger)sat used:(NSInteger)used;
- (NSInteger)getSignalForSat:(NSInteger)sat;
- (NSInteger)setSignalForSat:(NSInteger)sat signal:(NSInteger)signal;
- (void)redraw;


@end
