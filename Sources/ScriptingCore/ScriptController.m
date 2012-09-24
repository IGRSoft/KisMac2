/*
        
        File:			ScriptController.m
        Program:		KisMAC
	Author:			Michael Rossberg
				mick@binaervarianz.de
	Description:		KisMAC is a wireless stumbler for MacOS X.
                
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

#import "ScriptController.h"
#import "ScanController.h"
#import "ScanControllerPrivate.h"
#import "ScanControllerScriptable.h"
#import "WaveHelper.h"
#import "ScriptAdditions.h"
#import "KisMACNotifications.h"
#import "ScriptingEngine.h"

@implementation ScriptController

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tryToSave:) name:KisMACTryToSave object:nil];

    return self;
}

- (void)tryToSave:(NSNotification*)note {
    [self saveKisMACFile:nil];
}

#pragma mark -

- (void)showWantToSaveDialog:(SEL)overrideFunction {
	NSBeginAlertSheet(
        NSLocalizedString(@"Save Changes?", "Save changes dialog title"),
        NSLocalizedString(@"Save", "Save changes dialog button"),
        NSLocalizedString(@"Don't Save", "Save changes dialog button"),
        CANCEL, [WaveHelper mainWindow], self, NULL, @selector(saveDialogDone:returnCode:contextInfo:), overrideFunction, 
        NSLocalizedString(@"Save changes dialog text", "LONG dialog text")
        );
}

- (void)saveDialogDone:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(SEL)overrideFunction {
    switch (returnCode) {
    case NSAlertDefaultReturn:
        [self saveKisMACFileAs:nil];
    case NSAlertOtherReturn:
        break;
    case NSAlertAlternateReturn:
    default:
        [self performSelector:overrideFunction withObject:self];
    }
}

#pragma mark -

- (IBAction)showNetworks:(id)sender {
    [ScriptingEngine selfSendEvent:'KshN'];
}
- (IBAction)showTrafficView:(id)sender {
    [ScriptingEngine selfSendEvent:'KshT'];
}
- (IBAction)showMap:(id)sender {
    [ScriptingEngine selfSendEvent:'KshM'];
}
- (IBAction)showDetails:(id)sender {
    [ScriptingEngine selfSendEvent:'KshD'];
}

- (IBAction)toggleScan:(id)sender {
	[ScriptingEngine selfSendEvent:'KssS'];
}

#pragma mark -

- (IBAction)new:(id)sender {
    if ((sender!=self) && (![[NSApp delegate] isSaved])) {
        [self showWantToSaveDialog:@selector(new:)];
        return;
    }
   [ScriptingEngine selfSendEvent:'KNew'];
}

#pragma mark -

- (IBAction)openKisMACFile:(id)sender {
    NSOpenPanel *op;
    
    if ((sender!=self) && (![[NSApp delegate] isSaved])) {
        [self showWantToSaveDialog:@selector(openKisMACFile:)];
        return;
    }

    op=[NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:[NSArray arrayWithObject:@"kismac"]]==NSOKButton) {
        [ScriptingEngine selfSendEvent:'odoc' withClass:'aevt' andDefaultArgString:[op filename]];
    }
}

- (IBAction)openKisMAPFile:(id)sender {
    NSOpenPanel *op;
    
    op=[NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:[NSArray arrayWithObject:@"kismap"]]==NSOKButton) {
        [ScriptingEngine selfSendEvent:'odoc' withClass:'aevt' andDefaultArgString:[op filename]];
    }
}

#pragma mark -

- (IBAction)importKisMACFile:(id)sender {
    NSOpenPanel *op;
    int i;
    
    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:[NSArray arrayWithObject:@"kismac"]]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++) {
            NSString *file = [[op filenames] objectAtIndex:i];
            [ScriptingEngine selfSendEvent:'KImK' withDefaultArgString:file];
        }
    }
}
- (IBAction)importImageForMap:(id)sender {
    NSOpenPanel *op;

    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:[NSImage imageFileTypes]]==NSOKButton) {
		[ScriptingEngine selfSendEvent:'KImI' withDefaultArgString:[op filename]];
    }
}
- (IBAction)importPCPFile:(id)sender {
    NSOpenPanel *op;
    int i;
    
    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:nil]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++) {
            NSString *file = [[op filenames] objectAtIndex:i];
            [ScriptingEngine selfSendEvent:'KImP' withDefaultArgString:file];
        }
    }
}

#pragma mark -

- (IBAction)saveKisMACFile:(id)sender {
    NSString *filename = [[NSApp delegate] filename];
    if (!filename) {
        [self saveKisMACFileAs:sender];
    } else if (![ScriptingEngine selfSendEvent:'save' withClass:'core' andDefaultArgString:filename]) {
            [[NSApp delegate] showSavingFailureDialog];
    }
}

- (IBAction)saveKisMACFileAs:(id)sender {
    NSSavePanel *sp;
    
    sp=[NSSavePanel savePanel];
    [sp setRequiredFileType:@"kismac"];
    [sp setCanSelectHiddenExtension:YES];
    [sp setTreatsFilePackagesAsDirectories:NO];
    if ([sp runModal]==NSFileHandlingPanelOKButton) {
        if (![ScriptingEngine selfSendEvent:'KsaA' withDefaultArgString:[sp filename]]) 
            [[NSApp delegate] showSavingFailureDialog];    
    }
}

- (IBAction)saveKisMAPFile:(id)sender {
    NSSavePanel *sp;
    
    sp=[NSSavePanel savePanel];
    [sp setRequiredFileType:@"kismap"];
    [sp setCanSelectHiddenExtension:YES];
    [sp setTreatsFilePackagesAsDirectories:NO];
    if ([sp runModal]==NSFileHandlingPanelOKButton) {
        if (![ScriptingEngine selfSendEvent:'save' withClass:'core' andDefaultArgString:[sp filename]]) 
            [[NSApp delegate] showSavingFailureDialog];    
    }
}

#pragma mark -

#define WEPCHECKS {\
    if (![[NSApp delegate] selectedNetwork]) { NSBeep(); return; }\
    if ([[[NSApp delegate] selectedNetwork] passwordAvailable]) { [[NSApp delegate] showAlreadyCrackedDialog]; return; } \
    if ([[[NSApp delegate] selectedNetwork] wep] != encryptionTypeWEP && [[[NSApp delegate] selectedNetwork] wep] != encryptionTypeWEP40) { [[NSApp delegate] showWrongEncryptionType]; return; } \
    if ([[[[NSApp delegate] selectedNetwork] cryptedPacketsLog] count] < 8) { [[NSApp delegate] showNeedMorePacketsDialog]; return; } \
    }

- (IBAction)bruteforceNewsham:(id)sender {
    WEPCHECKS;
    [ScriptingEngine selfSendEvent:'KCBN'];
}

- (IBAction)bruteforce40bitLow:(id)sender {
    WEPCHECKS;
    [ScriptingEngine selfSendEvent:'KCBL'];
}

- (IBAction)bruteforce40bitAlpha:(id)sender {
    WEPCHECKS;
    [ScriptingEngine selfSendEvent:'KCBa'];
}

- (IBAction)bruteforce40bitAll:(id)sender {
    WEPCHECKS;
    [ScriptingEngine selfSendEvent:'KCBA'];
}

#pragma mark -

- (IBAction)wordlist40bitApple:(id)sender {
    WEPCHECKS;
    NSOpenPanel *op;
    int i;

    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:nil]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++)
            [ScriptingEngine selfSendEvent:'KCWa' withDefaultArgString:[[op filenames] objectAtIndex:i]];
    }
}

- (IBAction)wordlist104bitApple:(id)sender {
    WEPCHECKS;
    NSOpenPanel *op;
    int i;
    
    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:nil]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++)
            [ScriptingEngine selfSendEvent:'KCWA' withDefaultArgString:[[op filenames] objectAtIndex:i]];
    }
}

- (IBAction)wordlist104bitMD5:(id)sender {
    WEPCHECKS;
    NSOpenPanel *op;
    int i;
    
    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:nil]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++)
            [ScriptingEngine selfSendEvent:'KCWM' withDefaultArgString:[[op filenames] objectAtIndex:i]];
    }
}

- (IBAction)wordlistWPA:(id)sender {
    if (![[NSApp delegate] selectedNetwork]) { NSBeep(); return; }
    if ([[[NSApp delegate] selectedNetwork] passwordAvailable]) { [[NSApp delegate] showAlreadyCrackedDialog]; return; }
    if (([[[NSApp delegate] selectedNetwork] wep] != encryptionTypeWPA) && ([[[NSApp delegate] selectedNetwork] wep] != encryptionTypeWPA2 )){ [[NSApp delegate] showWrongEncryptionType]; return; }
	if ([[[NSApp delegate] selectedNetwork] SSID] == Nil) { [[NSApp delegate] showNeedToRevealSSID]; return; }
	if ([[[[NSApp delegate] selectedNetwork] SSID] length] > 32) { [[NSApp delegate] showNeedToRevealSSID]; return; }
	if ([[[NSApp delegate] selectedNetwork] capturedEAPOLKeys] == 0) { [[NSApp delegate] showNeedMorePacketsDialog]; return; }

    NSOpenPanel *op;
    int i;
    
    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:nil]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++)
            [ScriptingEngine selfSendEvent:'KCWW' withDefaultArgString:[[op filenames] objectAtIndex:i]];
    }
}

- (IBAction)wordlistLEAP:(id)sender {
    if (![[NSApp delegate] selectedNetwork]) { NSBeep(); return; }
    if ([[[NSApp delegate] selectedNetwork] passwordAvailable]) { [[NSApp delegate] showAlreadyCrackedDialog]; return; }
    if ([[[NSApp delegate] selectedNetwork] wep] != encryptionTypeLEAP) { [[NSApp delegate] showWrongEncryptionType]; return; }
	if ([[[NSApp delegate] selectedNetwork] capturedLEAPKeys] == 0) { [[NSApp delegate] showNeedMorePacketsDialog]; return; }
    NSOpenPanel *op;
    int i;
    
    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    if ([op runModalForTypes:nil]==NSOKButton) {
        for (i = 0; i < [[op filenames] count]; i++)
            [ScriptingEngine selfSendEvent:'KCWL' withDefaultArgString:[[op filenames] objectAtIndex:i]];
    }
}

#pragma mark -

- (IBAction)weakSchedulingAttack40bit:(id)sender {
    WEPCHECKS;
    NSAppleEventDescriptor *keyLen = [NSAppleEventDescriptor descriptorWithInt32:5];
    
    NSDictionary *args = [NSDictionary dictionaryWithObject:keyLen forKey:[NSString stringWithFormat:@"%d", 'KCKl']];
    [ScriptingEngine selfSendEvent:'KCSc' withArgs:args];
}

- (IBAction)weakSchedulingAttack104bit:(id)sender {
    WEPCHECKS;
    [ScriptingEngine selfSendEvent:'KCSc'];
}

- (IBAction)weakSchedulingAttack40And104bit:(id)sender {
    WEPCHECKS;
    NSAppleEventDescriptor *keyLen = [NSAppleEventDescriptor descriptorWithInt32:0xFFFFFF];
    
    NSDictionary *args = [NSDictionary dictionaryWithObject:keyLen forKey:[NSString stringWithFormat:@"%d", 'KCKl']];
    [ScriptingEngine selfSendEvent:'KCSc' withArgs:args];
}

#pragma mark -

- (IBAction)showNetworksInMap:(id)sender {
    BOOL show = ([sender state] == NSOffState);
    
    [ScriptingEngine selfSendEvent:'KMSN' withDefaultArg:[NSAppleEventDescriptor descriptorWithBoolean:show]];
}

- (IBAction)showTraceInMap:(id)sender {
    BOOL show = ([sender state] == NSOffState);
    
    [ScriptingEngine selfSendEvent:'KMST' withDefaultArg:[NSAppleEventDescriptor descriptorWithBoolean:show]];
}


#pragma mark -

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
@end
