/*
 
 File:			ScriptController.m
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

#import "BridgeController.h"
#import "ScanController.h"
#import "ScanControllerPrivate.h"
#import "ScanControllerScriptable.h"
#import "WaveHelper.h"
#import "KisMACNotifications.h"
#import "WaveNet.h"
#import "MapView.h"

@interface BridgeController ()

@property(nonatomic, strong) ScanController* scanController;

@end

@implementation BridgeController

- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(tryToSave:)
												 name:KisMACTryToSave
											   object:nil];

    return self;
}

- (ScanController *)scanController
{
    if (!_scanController)
    {
        _scanController = (ScanController*)[NSApp delegate];
    }
    
    return _scanController;
}

- (void)tryToSave:(NSNotification*)note
{
    [self saveKisMACFile:nil];
}

#pragma mark -

- (void)showWantToSaveDialog:(SEL)overrideFunction
{
	NSBeginAlertSheet(
        NSLocalizedString(@"Save Changes?", "Save changes dialog title"),
        NSLocalizedString(@"Save", "Save changes dialog button"),
        NSLocalizedString(@"Don't Save", "Save changes dialog button"),
        CANCEL, [WaveHelper mainWindow], self, NULL, @selector(saveDialogDone:returnCode:contextInfo:), overrideFunction, 
        NSLocalizedString(@"Save changes dialog text", "LONG dialog text")
        );
}

- (void)saveDialogDone:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(SEL)overrideFunction
{
    switch (returnCode)
    {
    case NSAlertDefaultReturn:
        [self saveKisMACFileAs:nil];
    case NSAlertOtherReturn:
        break;
    case NSAlertAlternateReturn:
    default:
		{
			NSMethodSignature *methodSignature = [self methodSignatureForSelector:overrideFunction];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
			[invocation setSelector:overrideFunction];
			//[invocation setArgument:&sheet atIndex:2];
			[invocation invoke];
		}
    }
}

#pragma mark -

- (IBAction)showNetworks:(id)sender
{
    [self.scanController showNetworks];
}
- (IBAction)showTrafficView:(id)sender
{
    [self.scanController showTrafficView];
}
- (IBAction)showMap:(id)sender
{
    [self.scanController showMap];
}
- (IBAction)showDetails:(id)sender
{
    [self.scanController showDetails];
}

- (IBAction)toggleScan:(id)sender
{
    [self.scanController toggleScan];
}

#pragma mark -

- (IBAction)tryNew:(id)sender
{
    if ((sender != self) && (![self.scanController isSaved]))
    {
        SEL newSelector = NSSelectorFromString(@"new:");
        [self showWantToSaveDialog:newSelector];
        
        return;
    }

    [self.scanController isNew];
}

#pragma mark -

- (IBAction)openKisMACFile:(id)sender
{
    if ((sender != self) && (![self.scanController isSaved]))
    {
        [self showWantToSaveDialog:@selector(openKisMACFile:)];
        
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op setAllowedFileTypes:@[@"kismac"]];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
             [self performSelector:@selector(openPath:) withObject:[[op URL] path] afterDelay:0.1];
             [op close];
		 }
	 }];
}

- (IBAction)openKisMAPFile:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op setAllowedFileTypes:@[@"kismap"]];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
             [self performSelector:@selector(openPath:) withObject:[[op URL] path] afterDelay:0.1];
             [op close];
		 }
		 
	 }];
}

- (void)openPath:(NSString*)path
{
    [self.scanController open:path];
}

#pragma mark -

- (IBAction)importKisMACFile:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op setAllowedFileTypes:@[@"kismac"]];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController importKisMAC:[[op URLs][i] path]];
			 }
		 }
	 }];
}
- (IBAction)importImageForMap:(id)sender
{
    NSOpenPanel *op;

    op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op setAllowedFileTypes:[NSImage imageFileTypes]];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
             [self.scanController importImageForMap:[[op URL] path]];
		 }
		 
	 }];
}
- (IBAction)importPCPFile:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController importPCAP:[[op URLs][i] path]];
			 }
		 }
		 
	 }];
}

#pragma mark -

- (IBAction)saveKisMACFile:(id)sender
{
    NSString *filename = [self.scanController filename];
    if (!filename)
    {
        [self saveKisMACFileAs:sender];
    }
    else if (![self.scanController save:filename])
    {
        [self.scanController showSavingFailureDialog];
    }
}

- (IBAction)saveKisMACFileAs:(id)sender
{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:@[@"kismac"]];
    [sp setCanSelectHiddenExtension:YES];
    [sp setTreatsFilePackagesAsDirectories:NO];
	[sp beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
             if (![self.scanController saveAs:[[sp URL] path]])
             {
                 [self.scanController showSavingFailureDialog];
             }
		 }
	 }];
}

- (IBAction)saveKisMAPFile:(id)sender
{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setAllowedFileTypes:@[@"kismap"]];
    [sp setCanSelectHiddenExtension:YES];
    [sp setTreatsFilePackagesAsDirectories:NO];
	[sp beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 if (![self.scanController save:[[sp URL] path]])
             {
				 [self.scanController showSavingFailureDialog];
             }
		 }
	 }];
}

#pragma mark -

- (BOOL) wepCheck
{
    BOOL result = YES;
    
    if (![self.scanController selectedNetwork])
    {
        NSBeep();
        result = NO;
    }
    if (result && [[self.scanController selectedNetwork] passwordAvailable])
    {
        [self.scanController showAlreadyCrackedDialog];
        result = NO;
    }
    if (result && [[self.scanController selectedNetwork] wep] != encryptionTypeWEP && [[self.scanController selectedNetwork] wep] != encryptionTypeWEP40)
    {
        [self.scanController showWrongEncryptionType];
        result = NO;
    }
    if (result && [[[self.scanController selectedNetwork] cryptedPacketsLog] count] < 8)
    {
        [self.scanController showNeedMorePacketsDialog];
        result = NO;
    }
    
    return result;
}

- (IBAction)bruteforceNewsham:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController bruteforceNewsham];
}

- (IBAction)bruteforce40bitLow:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController bruteforce40bitLow];
}

- (IBAction)bruteforce40bitAlpha:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController bruteforce40bitAlpha];
}

- (IBAction)bruteforce40bitAll:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController bruteforce40bitAll];
}

#pragma mark -

- (IBAction)wordlist40bitApple:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController wordlist40bitApple:[[op URLs][i] path]];
             }
		 }
		 
	 }];
}

- (IBAction)wordlist104bitApple:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController wordlist104bitApple:[[op URLs][i] path]];
             }
		 }
		 
	 }];
}

- (IBAction)wordlist104bitMD5:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController wordlist104bitMD5:[[op URLs][i] path]];
             }
		 }
		 
	 }];
}

- (IBAction)wordlistWPA:(id)sender
{
    if (![self.scanController selectedNetwork])
    {
        NSBeep();
        return;
    }
    if ([[self.scanController selectedNetwork] passwordAvailable])
    {
        [self.scanController showAlreadyCrackedDialog];
        return;
    }
    if (([[self.scanController selectedNetwork] wep] != encryptionTypeWPA) && ([[self.scanController selectedNetwork] wep] != encryptionTypeWPA2 ))
    {
        [self.scanController showWrongEncryptionType];
        return;
    }
	if ([[self.scanController selectedNetwork] SSID] == nil)
    {
        [self.scanController showNeedToRevealSSID];
        return;
    }
	if ([[[self.scanController selectedNetwork] SSID] length] > 32)
    {
        [self.scanController showNeedToRevealSSID];
        return;
    }
	if ([[self.scanController selectedNetwork] capturedEAPOLKeys] == 0)
    {
        [self.scanController showNeedMorePacketsDialog];
        return;
    }

    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController wordlistWPA:[[op URLs][i] path]];
             }
		 }
		 
	 }];
}

- (IBAction)wordlistLEAP:(id)sender
{
    if (![self.scanController selectedNetwork])
    {
        NSBeep();
        return;
    }
    if ([[self.scanController selectedNetwork] passwordAvailable])
    {
        [self.scanController showAlreadyCrackedDialog];
        return;
    }
    if ([[self.scanController selectedNetwork] wep] != encryptionTypeLEAP)
    {
        [self.scanController showWrongEncryptionType];
        return;
    }
	if ([[self.scanController selectedNetwork] capturedLEAPKeys] == 0)
    {
        [self.scanController showNeedMorePacketsDialog];
        return;
    }
   
	NSOpenPanel * op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
	[op beginWithCompletionHandler:^(NSInteger result)
	 {
		 if (result == NSFileHandlingPanelOKButton)
		 {
			 for (NSInteger i = 0; i < [[op URLs] count]; ++i)
             {
                 [self.scanController wordlistLEAP:[[op URLs][i] path]];
             }
		 }
		 
	 }];
}

#pragma mark -

- (IBAction)weakSchedulingAttack40bit:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController weakSchedulingAttackForKeyLen:5 andKeyID:0];
}

- (IBAction)weakSchedulingAttack104bit:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController weakSchedulingAttackForKeyLen:13 andKeyID:0];
}

- (IBAction)weakSchedulingAttack40And104bit:(id)sender
{
    if (![self wepCheck])
    {
        return;
    }
    
    [self.scanController weakSchedulingAttackForKeyLen:0xFFFFFF andKeyID:0];
}

#pragma mark -

- (IBAction)showNetworksInMap:(id)sender
{
    BOOL show = ([sender state] == NSOffState);
    
    [[WaveHelper mapView] setShowNetworks:show];
}

- (IBAction)showTraceInMap:(id)sender
{
    BOOL show = ([sender state] == NSOffState);
    
    [[WaveHelper mapView] setShowTrace:show];
}


#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
