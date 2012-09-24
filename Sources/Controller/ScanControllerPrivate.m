/*
        
        File:			ScanControllerPrivate.m
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

#include <unistd.h>

#import <BIGeneric/BIGeneric.h>
#import "ScanControllerPrivate.h"
#import "ScanControllerScriptable.h"
#import "WaveHelper.h"
#import "WaveNetWPACrack.h"
#import "SpinChannel.h"
#import "../WaveDrivers/WaveDriver.h"
#import "MapView.h"
#import "MapViewAreaView.h"
#import "GPSController.h"

@implementation ScanController(PrivateExtension) 

- (void)updateChannelMenu {
    NSUserDefaults *sets;
    NSArray *a;
    unsigned int x, c, lc;
    NSMenuItem *mi;
    WaveDriver *wd;
    WaveDriver *actWD = Nil;
    NSDictionary *config;
    NSString *whichDriver;
    sets=[NSUserDefaults standardUserDefaults];
    
    for (x = 0; x < _activeDriversCount; x++) {
        [aChannelMenu removeItemAtIndex:0];
    }
    _activeDriversCount = 0;
    
    a = [WaveHelper getWaveDrivers];
    if ([a count] == 0) {
        mi = (NSMenuItem*)[aChannelMenu insertItemWithTitle:NSLocalizedString(@"(No driver loaded)", "menu item") action:@selector(selDriver:) keyEquivalent:@"" atIndex:0];
        [mi setEnabled:NO];
        _whichDriver = Nil;
        _activeDriversCount = 1;
        
        for (x = 0; x < [aChannelMenu numberOfItems]; x++)
           [[aChannelMenu itemAtIndex:x] setEnabled: NO];

    } else {
        a = [a sortedArrayUsingSelector:@selector(compareDrivers:)];

        whichDriver = [sets objectForKey:@"whichDriver"];
        if (!whichDriver) {
			whichDriver = [[a objectAtIndex:0] deviceName];
			[sets setObject:whichDriver forKey:@"whichDriver"];
		}
		
        for (x = 0; x < [a count]; x++) {
            wd = [a objectAtIndex:x];
            mi = (NSMenuItem*)[aChannelMenu insertItemWithTitle:[wd deviceName] action:@selector(selDriver:) keyEquivalent:@"" atIndex:0];
            _activeDriversCount++;
            if ([[wd deviceName] isEqualToString: whichDriver]) {
                [mi setState:NSOnState];
                actWD = wd;
            }
        }
        
        if (!actWD) { //driver is not loaded anymore?
            whichDriver = [[a objectAtIndex:0] deviceName];
            [sets setObject:whichDriver forKey:@"whichDriver"];
            
            [self updateChannelMenu];
            return;
        }
        [WaveHelper secureReplace:&_whichDriver withObject:whichDriver];

        
        for (x = _activeDriversCount; x < [aChannelMenu numberOfItems]; x++) {
           mi = (NSMenuItem*)[aChannelMenu itemAtIndex:x];
           if (![mi isSeparatorItem]) [mi setEnabled:[actWD allowsChannelHopping]];
        }
        
        [[aChannelMenu itemAtIndex:_activeDriversCount+4] setState: [actWD ETSI] ? NSOnState : NSOffState];
        [[aChannelMenu itemAtIndex:_activeDriversCount+3] setState: [actWD FCC]  ? NSOnState : NSOffState];
        
        config = [actWD configuration];
        
        c = 0;
        lc = 0;
        
        for (x = 1; x <= 14; x++) {
            if ([[config objectForKey:[NSString stringWithFormat:@"useChannel%.2i",x]] intValue]) {
                c++;
                lc = x;
            }
        }
        
        for (x = 1; x <= 14; x++)
            [[aChannelMenu itemAtIndex:x + 5 + _activeDriversCount] setState:((c==1 && lc == x) ? NSOnState : NSOffState)];
        
        [[aChannelMenu itemAtIndex: _activeDriversCount + 1] setState:([actWD autoAdjustTimer]? NSOnState : NSOffState)];

        //just make sure the driver knows about its configuration
        [actWD setConfiguration: [actWD configuration]];
    }
}

- (void)menuSetEnabled:(bool)a menu:(NSMenu*)menu {
    int x;
    
    [menu setAutoenablesItems:a];
    for (x=0;x<[menu numberOfItems];x++) 
        if ([[menu itemAtIndex:x] hasSubmenu]) [self menuSetEnabled:a menu:[[menu itemAtIndex:x] submenu]];
        else [[menu itemAtIndex:x] setEnabled:a];
}

#pragma mark -

- (void)updatePrefs:(NSNotification*)note {
    NSUserDefaults *sets;
    int x;
    NSString* key;
    
    sets=[NSUserDefaults standardUserDefaults];

    if ([sets integerForKey:@"GeigerSensity"]<1) [sets setInteger:1 forKey:@"GeigerSensity"];
    key=[sets objectForKey:@"GeigerSound"];
    if ([key isEqualToString:@"None"]) key=Nil;
    [scanner setGeigerInterval:[sets integerForKey:@"GeigerSensity"] sound:key];

    if ([sets floatForKey:@"frequence"]<0.2) [sets setFloat:0.25 forKey:@"frequence"];
    [scanner setFrequency:[sets floatForKey:@"frequence"]];

	if(_refreshGPS) {
		[WaveHelper initGPSControllerWithDevice: [sets objectForKey:@"GPSDevice"]];
		_refreshGPS = NO;
	}
    
    switch ([[sets objectForKey:@"GPSTrace"] intValue]) {
        case 0: x = 100; break;
        case 1: x = 20;  break;
        case 2: x = 10;  break;
        case 3: x = 5;   break;
        case 4: x = 1;   break;
        case 5: x = 0;   break;
        default: x = 100;
    }
    
    [[WaveHelper gpsController] setTraceInterval:x];
    [[WaveHelper gpsController] setOnNoFix:[[sets objectForKey:@"GPSNoFix"] intValue]];
    [[WaveHelper gpsController] setTripmateMode:[[sets objectForKey:@"GPSTripMate"] boolValue]];
    
    [self updateChannelMenu];
}

#pragma mark -

- (void)selectNet:(WaveNet*)net {
    _curNet=net;
    if (net!=nil) {
        [self menuSetEnabled:YES menu:aNetworkMenu];
        [_showNetInMap setEnabled:YES];
        [aInfoController showNet:net];
        _selectedRow = 0;
    } else {
        [aInfoController showNet:nil];
        [_detailsDrawer close];
        [_detailsDrawerMenu setTitle: NSLocalizedString(@"Show Details", "menu item")];
        _detailsPaneVisibile = NO;

        [self menuSetEnabled:NO menu:aNetworkMenu];
        [_showNetInMap setEnabled:NO];
        _selectedRow = [_networkTable selectedRow] - 1;
    }
}

#pragma mark -

- (void)changedViewTo:(__availableTabs)tab contentView:(NSView*)view {
    if (_visibleTab == tab) return;
    
    _visibleTab = tab;
    
    if(tab == tabNetworks) {
        [self updateNetworkTable:self complete:YES];
    }

    [_showNetworks      setState: tab == tabNetworks ? NSOnState : NSOffState];
    [_showTraffic       setState: tab == tabTraffic  ? NSOnState : NSOffState];
    [_showMap           setState: tab == tabMap      ? NSOnState : NSOffState];
    [_showDetails       setState: tab == tabDetails  ? NSOnState : NSOffState];
    [_searchField       setHidden: tab != tabNetworks && tab != tabMap];
	[_searchTypeMenu        setHidden: tab != tabNetworks && tab != tabMap]; 
    [_trafficTimePopUp  setHidden: tab != tabTraffic];
    [_trafficModePopUp  setHidden: tab != tabTraffic];
    [_mappingView       setVisible: tab == tabMap];
    [_networksButton    setImage: [NSImage imageNamed:tab == tabNetworks ? @"networks-highlight.tif" : @"networks-button.tif"]];
    [_trafficButton     setImage: [NSImage imageNamed:tab == tabTraffic  ? @"traffic-highlight.tif"  : @"traffic-button.tif"]];
    [_mapButton         setImage: [NSImage imageNamed:tab == tabMap      ? @"map-highlight.tif"      : @"map-button.tif"]];
    [_detailsButton     setImage: [NSImage imageNamed:tab == tabDetails  ? @"details-highlight.tif"  : @"details-button.tif"]];
    [_window            setAcceptsMouseMovedEvents: tab == tabMap]; //need to track the mouse in this view

    if (tab != tabNetworks) [self hideDetails];
 
    [_mainView setContentView:view];
	[_toolBar setNeedsDisplay:YES];
    if (_importOpen == 0) [_window display];  //seems to be not possible if in modal mode
}

- (void)showDetailsFor:(WaveNet*)net {
    [self selectNet:net];
    [_detailsDrawer close];
    [_detailsDrawerMenu setTitle: NSLocalizedString(@"Show Details", "menu item")];
    _detailsPaneVisibile = NO;
    
    //if ([aTabView indexOfTabViewItemWithIdentifier:@"details"]==NSNotFound)
    //    [aTabView addTabViewItem:aDetails];
    
    [self showDetails];
}

- (void)hideDetails {
    //if ([aTabView indexOfTabViewItemWithIdentifier:@"details"]!=NSNotFound) {
    //    [aTabView removeTabViewItem:[aTabView tabViewItemAtIndex:[aTabView indexOfTabViewItemWithIdentifier:@"details"]]];
    //    _visibleTab = tabNetworks;
    //}
}

#pragma mark -

- (void)crackDone:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	int i;
	
    _importOpen--;
	NSParameterAssert(_importOpen == 0);
	[self menuSetEnabled:YES menu:[NSApp mainMenu]];
	NSUserDefaults *defs;

	[aInfoController reloadData];
    
    [[_importController window] close];
    [_importController stopAnimation];

    if (returnCode == -1 && ![_importController canceled]) {
		defs = [NSUserDefaults standardUserDefaults];
		if([[defs objectForKey:@"playCrackSounds"] intValue]) {
			for (i=0;i<3;i++) {
				[[NSSound soundNamed:[[NSUserDefaults standardUserDefaults] objectForKey:@"WEPSound"]] play];
				sleep(1);
			}
		}
		switch(_crackType) {
        case 1:
            NSBeginAlertSheet(NSLocalizedString(@"Cracking unsuccessful", "Error box title for WEP attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            NSLocalizedString(@"Cracking unsuccessful description for weak scheduling attack", "LONG description with possible causes"));
            //@"KisMAC was not able to recover the WEP key. This is either because you have not collected enough weak keys, you will need a value way bigger than 1000. Or another reason might be the fact that the base station is using extended features like WEP+ or the key was simply changed during the collection process.");
            break;
        case 2:
            NSBeginAlertSheet(NSLocalizedString(@"Cracking unsuccessful", "Error box title for WEP attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            NSLocalizedString(@"Cracking unsuccessful description for brutforce", "LONG description with possible causes")
            //@"The key could not have been recovered. Possible reasons are: 1. The key was not a 40-bit key. 2.The crypto algorithm is not WEP. 3. Advanced Features like LEAP are activated."
            );
            break;
        case 3:
            NSBeginAlertSheet(NSLocalizedString(@"Cracking unsuccessful", "Error box title for WEP attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            [NSString stringWithFormat:
                NSLocalizedString(@"The WPA key could not be recovered, because for the following reason: %@.", "description why WPA crack failed"),
                [_curNet crackError]]
            );
            break;
        case 4:
            NSBeginAlertSheet(NSLocalizedString(@"Cracking unsuccessful", "Error box title for WEP attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            [NSString stringWithFormat:
                NSLocalizedString(@"The LEAP key could not be recovered, because for the following reason: %@.", "description why LEAP crack failed"),
                [_curNet crackError]]
            );
        case 5:
            NSBeginAlertSheet(NSLocalizedString(@"Reinjection unsuccessful", "Error dialog title"),
                OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
                NSLocalizedString(@"KisMAC was unable to start a reinjection attack, because: %@", "text about what might have gone wrong with the injection"),
                [_curNet crackError]
                );
            [self stopActiveAttacks];
            break;
		case 6:
            NSBeginAlertSheet(NSLocalizedString(@"Cracking unsuccessful", "Error box title for WEP attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            NSLocalizedString(@"Cracking unsuccessful description for newsham", "LONG description with possible causes")
            );
            break;
        default:
            break;
        }
    } else if (returnCode==1) {
        if (_crackType == 5) {
            [aInjPacketsMenu setState:NSOnState];
            [aInjPacketsMenu setTitle:[NSLocalizedString(@"Reinjecting into ", "menu item") stringByAppendingString:[_curNet BSSID]]];
        } else {
			defs = [NSUserDefaults standardUserDefaults];
			if([[defs objectForKey:@"playCrackSounds"] intValue]) {
				for (i=0;i<3;i++) {
					[[NSSound soundNamed:[[NSUserDefaults standardUserDefaults] objectForKey:@"noWEPSound"]] play];
					sleep(1);
				}
			}
			NSBeginAlertSheet(NSLocalizedString(@"Cracking successful", "Crack dialog title"),
                OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
                NSLocalizedString(@"KisMAC was able to recover the key of the selected network. It is: %@", "crack dialog"),
                [_curNet key]
                );
		}
    }

    [_importController release];
    _importController=Nil;
}

- (void)startCrackDialogWithTitle:(NSString*)title stopScan:(BOOL)stopScan {
    NSParameterAssert(title);
    NSParameterAssert(_importOpen == 0); //we are already busy
	_importOpen++;
	[self menuSetEnabled:NO menu:[NSApp mainMenu]];
	
    if (stopScan) [self stopScan];
    
    _importController = [[ImportController alloc] initWithWindowNibName:@"Crack"];
    [_importController setTitle:title];
    [WaveHelper setImportController:_importController];
	
    [NSApp beginSheet:[_importController window] modalForWindow:_window modalDelegate:self didEndSelector:@selector(crackDone:returnCode:contextInfo:) contextInfo:nil];
}

- (void)startCrackDialogWithTitle:(NSString*)title {
    [self startCrackDialogWithTitle:title stopScan:YES];
}

- (void)startCrackDialog {
    [self startCrackDialogWithTitle:NSLocalizedString(@"Cracking...", "default status string for crack dialog") stopScan:YES];
}

- (bool)startActiveAttack {
    WaveDriver *wd;
    
    if (_curNet == Nil) {
        NSBeginAlertSheet(NSLocalizedString(@"No network selected.", "Error box title for active attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            NSLocalizedString(@"No network selected failure description", "LONG description")
            //@"You will have to select a network, which you wish to attack!"
            );
        return NO;
    }
    
    if (![WaveHelper loadDrivers]) return NO;         // the user canceled or did not enter password
    
    wd = [WaveHelper injectionDriver];
    if (!wd) {
         NSBeginAlertSheet(NSLocalizedString(@"No injection driver.", "Error box title for active attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            NSLocalizedString(@"No injection driver failure description", "LONG text about where you can enable it")
            //@"You have no primary injection driver chosen, please select one in the preferences dialog."
            );
        return NO;
    }
    
    if ([wd hopping]) {
        NSBeginAlertSheet(NSLocalizedString(@"Channel hopping enabled.", "Error box title for active attacks"),
            OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
            NSLocalizedString(@"Channel hopping enabled failure description", "LONG text about why this does not work with active attacks")
            //@"You have channel hopping enabled! In order to send frames correctly you will need to disable it and select a channel, where you can receive the network correctly."
            );
        return NO;
    }
    
    if (_activeAttackNetID) [self stopActiveAttacks];
    
    _activeAttackNetID = [[_curNet ID] retain];
    
    return YES;
}

- (void)stopActiveAttacks {
    [_activeAttackNetID release];
    _activeAttackNetID = Nil;
    
    [scanner stopSendingFrames];
	[scanner setDeauthingAll:NO];
    
    [_deauthAllMenu setState: NSOffState];
    [_deauthMenu setState: NSOffState];
    [_deauthMenu setTitle: NSLocalizedString(@"Deauthenticate", "menu item. description must be the same as in MainMenu.nib!")];
    [_authFloodMenu setState: NSOffState];
    [_authFloodMenu setTitle: NSLocalizedString(@"Authentication Flood", "menu item. description must be the same as in MainMenu.nib!")];
    [aInjPacketsMenu setState: NSOffState];
    [aInjPacketsMenu setTitle: NSLocalizedString(@"Reinject Packets", "menu item. description must be the same as in MainMenu.nib!")];
}


#pragma mark -

- (void)clearAreaMap {
    [_mappingView clearAreaNet];
    [_showNetInMap setTitle: NSLocalizedString(@"Show Net Area", "menu item. description must be the same as in MainMenu.nib!")];
    [_showNetInMap setState: NSOffState];
    [_showAllNetsInMap setState: NSOffState];
}

- (void)advNetViewInvalid:(NSNotification*)note {
    [self clearAreaMap];
}

- (void)networkAdded:(NSNotification*)note {
    [self updateNetworkTable:self complete:YES];
}

#pragma mark -

- (void)refreshScanHierarch {
    if (!_refreshGUI) return;
    
    [ScanHierarch clearAllItems];
    [ScanHierarch updateTree];
    [aOutView reloadData];
}

#pragma mark -

- (void)modalDone:(NSNotification*)note {
    [self busyDone];
}

- (void)showBusyWithText:(NSString*)title {
	[self showBusyWithText:title andEndSelector:nil andDialog:@"Import"];
}

- (void)showBusyWithText:(NSString*)title andEndSelector:(SEL)didEndSelector andDialog:(NSString*)dialog {
    NSParameterAssert(title);
    NSParameterAssert(dialog);	
    if (_importOpen++ > 0) return; //we are already busy
	[self menuSetEnabled:NO menu:[NSApp mainMenu]];
    
    _importController = [[ImportController alloc] initWithWindowNibName:dialog];
    if (!_importController) {
        NSLog(@"Error could not open Import.nib!");
        return;
    }

    [WaveHelper setImportController:_importController];
    [_importController setTitle:title];
	
    [NSApp beginSheet:[_importController window] modalForWindow:_window modalDelegate:self didEndSelector:didEndSelector contextInfo:nil];
}

- (void)busyDone {
    if (_importOpen == 0) return; //the import controller was already closed!!
    if (--_importOpen > 0) return; //still retains
	[self menuSetEnabled:YES menu:[NSApp mainMenu]];
	
    if (_importController) [NSApp endSheet:[_importController window]];
    [[_importController window] orderOut:self];
    [WaveHelper secureRelease:&_importController];   
}

- (void)showBusy:(SEL)function withArg:(id)obj {
    [obj retain];
    _busyFunction = function;
    
    _importController = [[ImportController alloc] initWithWindowNibName:@"Import"];
    if (!_importController) {
        NSLog(@"Error could not open Import.nib!");
        return;
    }
    _doModal = YES;

	[self menuSetEnabled:NO menu:[NSApp mainMenu]];
    [NSApp beginSheet:[_importController window] modalForWindow:_window modalDelegate:self didEndSelector:nil contextInfo:nil];
      
    [self performSelector:_busyFunction withObject:obj];
        
    [obj release];

    [self menuSetEnabled:YES menu:[NSApp mainMenu]];
    [NSApp endSheet: [_importController window]];        
    [[_importController window] close];
    [_importController stopAnimation];
    [WaveHelper secureRelease:&_importController];
}

- (void)busyThread:(id)anObject {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self performSelector:_busyFunction withObject:anObject];
    
    _doModal = NO;
	
	[self menuSetEnabled:YES menu:[NSApp mainMenu]];
    [NSApp endSheet: [_importController window]];        
    [[_importController window] orderOut:self];
    [[_importController window] close];
    [_importController stopAnimation];
    [pool release];
}

#pragma mark -

- (void)showWantToSaveDialog:(SEL)overrideFunction {
    [self menuSetEnabled:NO menu:[NSApp mainMenu]];
    NSBeginAlertSheet(
        NSLocalizedString(@"Save Changes?", "Save changes dialog title"),
        NSLocalizedString(@"Save", "Save changes dialog button"),
        NSLocalizedString(@"Don't Save", "Save changes dialog button"),
        CANCEL, _window, self, NULL, overrideFunction, self, 
        NSLocalizedString(@"Save changes dialog text", "LONG dialog text")
        //@"You have been scanning since your last save. Do you want to save your results?"
        );
}

- (void)showExportFailureDialog {
    NSBeginCriticalAlertSheet(
        NSLocalizedString(@"Export failed", "Export failure dialog title"),
        OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
        NSLocalizedString(@"Export failure description", "LONG Export failure dialog text. Permissions?!")
        //@"KisMAC was unable to complete the export, because of an I/O error. Are permissions correct?"
        );
}

- (void)showSavingFailureDialog {
    NSBeginCriticalAlertSheet(
        NSLocalizedString(@"Saving failed", "Saving failure dialog title"),
        OK, NULL, NULL, _window, self, NULL, NULL, NULL, 
        NSLocalizedString(@"Saving failure description", "LONG Saving failure dialog text. Permissions?!")
        //@"KisMAC was unable to complete the saving process, because of an I/O error. Are permissions correct?"
        );
}

- (void)showAlreadyCrackedDialog {
    NSBeginAlertSheet(ERROR_TITLE, 
        OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL,
        NSLocalizedString(@"KisMAC did already reveal the password.", @"Error description for cracking.")
        );
}

- (void)showWrongEncryptionType {
    NSBeginAlertSheet(ERROR_TITLE, 
        OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL,
        NSLocalizedString(@"The encryption of the selected network does not work with this attack.", @"Error description for cracking.")
        );
}

- (void)showNeedMorePacketsDialog {
    NSBeginAlertSheet(ERROR_TITLE, 
        OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL,
        NSLocalizedString(@"Need more packets description", "LONG dialog text. The user needs more packets. active scanners are not able to do this")
        //@"You have not collected enough data packets to perform this attack. Please capture some more traffic"
        );
}

- (void)showNeedMoreWeakPacketsDialog {
    NSBeginAlertSheet(ERROR_TITLE,
        OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL,
        NSLocalizedString(@"Need more weak packets description", "LONG dialog text. The user needs more weak packets. explain")
        //@"KisMAC cannot recover your WEP key, using this method. The weak scheduling attack requires a lot of weak keys. Please see the help file for more details."
        );
}

- (void)showNeedToRevealSSID {
    NSBeginAlertSheet(ERROR_TITLE, 
        OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL,
        NSLocalizedString(@"You will need to reveal a valid SSID before you are able to attack this network. The SSID is a vital part of the WPA encryption process", "Explain")
        );
}
        
@end
