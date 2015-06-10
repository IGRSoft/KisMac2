/*
 
 File:			PrefsDriver.h
 Program:		KisMAC
 Author:		Michael Thole
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

#import "PrefsClient.h"

@interface PrefsDriver : PrefsClient
{
    IBOutlet NSTextField    *_frequence;
    IBOutlet NSTextField    *_firstChannel;
    IBOutlet NSMatrix       *_channelSel;
    IBOutlet NSButton       *_selAll;
    IBOutlet NSButton       *_selNone;
	
    IBOutlet NSButton       *_injectionDevice;
    
    IBOutlet NSPopUpButton  *_driver;
    IBOutlet NSButton       *_removeDriver;
    IBOutlet NSTableView    *_driverTable;

    IBOutlet NSMatrix       *_dumpFilter;
    IBOutlet NSTextField    *_dumpDestination;
	
	IBOutlet NSTextField	*_kismet_host;
	IBOutlet NSTextField	*_kismet_port;
    	
	IBOutlet NSBox			*_chanhop;
	IBOutlet NSBox			*_kdrone_settings;
	IBOutlet NSBox			*_injection;
	IBOutlet NSBox			*_dumpFilterBox;
	IBOutlet NSBox			*_savedumpsat;
	IBOutlet NSBox			*_globalsettings;
}

- (IBAction)selAddDriver:(id)sender;
- (IBAction)selRemoveDriver:(id)sender;

- (IBAction)selAll:(id)sender;
- (IBAction)selNone:(id)sender;

@end
