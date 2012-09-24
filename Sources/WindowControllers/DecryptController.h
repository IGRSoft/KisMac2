/*
        
        File:			DecryptController.h
        Program:		KisMAC
		Author:			Michael Rossberg
						mick@binaervarianz.de
		Description:	KisMAC is a wireless stumbler for MacOS X.
                
        This file is part of KisMAC.

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
#import <AppKit/AppKit.h>

@interface DecryptController : NSWindowController <NSWindowDelegate>
{
    IBOutlet NSButton* _okButton;
    IBOutlet NSButton* _cancelButton;
    IBOutlet NSTextField* _inFile;
    IBOutlet NSTextField* _outFile;
    IBOutlet NSTextField* _hexKey;
    IBOutlet NSButton* _newInFile;
    IBOutlet NSButton* _newOutFile;
    IBOutlet NSPopUpButton* _cryptMethod;
}

- (IBAction)okAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)otherFile:(id)sender;
@end
