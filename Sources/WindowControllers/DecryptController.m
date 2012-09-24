/*
        
        File:			DecryptController.m
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

#import "DecryptController.h"
#import <CoreFoundation/CFString.h>
#import "80211b.h"
#import "RC4.h"
#import <pcap.h>
#import "WaveHelper.h"
#import "FCS.h"
#import "../3rd Party/Apple80211.h"

typedef struct _header {
    /* 802.11 Header Info (Little Endian) */
    UInt16 frameControl;
    UInt8  duration;
    UInt8  id;
    UInt8  address1[6];
    UInt8  address2[6];
    UInt8  address3[6];
    UInt16 sequenceControl;
    UInt8  data[100];
} __attribute__((packed)) header;

unsigned long doFCS(unsigned char* buf, int len) {
    int i;
    unsigned long crc=0xffffffff;
    for(i=0;i<len;i++) {
        crc=UPDC32(buf[i],crc);
    }
    return(crc);
}

@implementation DecryptController

- (void)awakeFromNib {
    [[self window] setDelegate:self];
} 

- (IBAction)okAction:(id)sender {
    NSString *inFile, *outFile;
    NSMutableString *key;
    const char *c;
    UInt8 ckey[16], kkey[16];
    NSFileManager *fileMan;
    BOOL isDir;
    unsigned int i, keylen, tmp, decCount = 0, decError = 0, s, val, shift;
    char err[PCAP_ERRBUF_SIZE];
    const u_char *b;
    struct pcap_pkthdr h;
    pcap_t *aPCapIN;
    pcap_dumper_t* pw;
    RC4 rc;
    header* f;
    UInt8 x[3000];
    UInt8 *data;
    int framelen;
    
    if ([[_outFile stringValue] isEqualToString:@""]) {
        NSBeginAlertSheet(
            NSLocalizedString(@"No output file given.", "Decrypt error title"),
            OK, nil, nil, [self window], nil, nil, nil, nil,
            NSLocalizedString(@"KisMAC needs the name of an output file, where it can save the decrypted dump!", "Decrypt error")
            );
        return;
    }

    if ([[_inFile stringValue] isEqualToString:@""]) {
        NSBeginAlertSheet(
            NSLocalizedString(@"No input file given.", "Decrypt error title"),
            OK, nil, nil, [self window], nil, nil, nil, nil,
            NSLocalizedString(@"KisMAC needs the name of an input file, which it shall decrypt!", "Decrypt error")
            );
        return;
    }
    
    inFile = [[_inFile stringValue] stringByExpandingTildeInPath];
    fileMan = [NSFileManager defaultManager];
    if ((![fileMan fileExistsAtPath:inFile isDirectory:&isDir])|| isDir) {
        NSBeginAlertSheet(
            NSLocalizedString(@"Input file does not exist!", "Decrypt error title"),
            OK, nil, nil, [self window], nil, nil, nil, nil,
            NSLocalizedString(@"KisMAC needs the name of an input file, which it shall decrypt!", "Decrypt error")
            );
        return;
    }
    
    if ([[_hexKey stringValue] isEqualToString:@""]) {
        NSBeginAlertSheet(
            NSLocalizedString(@"No key entered.", "Decrypt error title"),
            OK, nil, nil, [self window], nil, nil, nil, nil,
            NSLocalizedString(@"KisMAC needs a password or a key in order to decrypt a file!", "Decrypt error")
            );
        return;
    }
    
    switch([_cryptMethod indexOfSelectedItem]) {
    case 0:
        WirelessEncrypt((CFStringRef)[_hexKey stringValue],(WirelessKey*)ckey,0);
        keylen = 5;
        break;
    case 1:
        WirelessEncrypt((CFStringRef)[_hexKey stringValue],(WirelessKey*)ckey,1);
        keylen = 13;
        break;
    case 2:
    case 3:
        key = [NSMutableString stringWithString:[[[_hexKey stringValue] stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] invertedSet]] lowercaseString]];
        
        [key replaceOccurrencesOfString:@":" withString:@"" options:0 range:NSMakeRange(0, [key length])];
        
        if ([_cryptMethod indexOfSelectedItem]==2) keylen = 5;
        else keylen = 13;
        
        if ([key length]!=keylen*2) {
            NSBeginAlertSheet(
                NSLocalizedString(@"Invalid hex key.", "Decrypt error title"),
                OK, nil, nil, [self window], nil, nil, nil, nil,
                NSLocalizedString(@"The hex key, that you entered is invalid. It must consist only of A-F and 0-9 signs and needs to have a specific length.", "Decrypt error")
                );
            return;
        }
        
        c = [key UTF8String];
        for (i=0; i<keylen;i++) {
            if (sscanf(&c[i*2],"%2x", &tmp) != 1) {
                NSBeginAlertSheet(
                    NSLocalizedString(@"Invalid hex key.", "Decrypt error title"),
                    OK, nil, nil, [self window], nil, nil, nil, nil,
                    NSLocalizedString(@"The hex key, that you entered is invalid. It must consist only of A-F and 0-9 signs and needs to have a specific length.", "Decrypt error")
                    );
                return;
            }
            ckey[i] = tmp & 0xFF;
        }
        break;
    case 4:
        WirelessCryptMD5([[_hexKey stringValue] UTF8String], ckey);
        keylen = 13;
        break;
    case 5:
        c = [[_hexKey stringValue] UTF8String];
        
        val = 0;
        for(i = 0; i < [[_hexKey stringValue] length]; i++) 
        {
            shift = i & 0x3;
            val ^= (c[i] << (shift * 8));
        }
        
        for(i = 0; i < 5; i++) {
            val *= 0x343fd;
            val += 0x269ec3;
            ckey[i] = val >> 16;
        }

        keylen = 5;
        break;
    default:
        NSAssert(NO, @"Invalid selection"); 
        keylen = 0;
    }
    
    outFile = [[_outFile stringValue] stringByExpandingTildeInPath];
    
    aPCapIN=pcap_open_offline([inFile UTF8String],err);
    if (aPCapIN==NULL) {
        NSBeginAlertSheet(
            NSLocalizedString(@"Could not open input Dump.", "Decrypt error title"),
            OK, nil, nil, [self window], nil, nil, nil, nil,
            [NSString stringWithFormat: 
                @"%@: %s!", 
                NSLocalizedString(@"KisMAC was unable to open the input file because of the following error", "Decrypt error"),
                err
            ]
            );
        return;
    }

    pw=pcap_dump_open(aPCapIN,[outFile UTF8String]);
    if (pw==NULL) {
        NSBeginAlertSheet(
            NSLocalizedString(@"Could not open output dump.", "Decrypt error title"),
            OK, nil, nil, [self window], nil, nil, nil, nil,
            NSLocalizedString(@"KisMAC was unable to open the output file!", "Decrypt error")
            );
        goto error1;
    }
    
    setupIdentity();		//initialized the RC4 sboxes
    memcpy(kkey+3, ckey, keylen);
    
    while ((b=pcap_next(aPCapIN,&h)) != NULL) {
        memcpy(x,b,h.caplen);
        f=(header*)x;
        if (((f->frameControl & IEEE80211_TYPE_MASK)==IEEE80211_TYPE_DATA) && (h.caplen>=32) && ((f->frameControl & IEEE80211_WEP)==IEEE80211_WEP)) {
            //shall we handle a tunnel?
            if ((f->frameControl & IEEE80211_DIR_MASK) == IEEE80211_DIR_DSTODS) {
                data = f->data + 4;
                framelen = h.caplen - 4;
            } else {
                data = f->data;
                framelen = h.caplen;
            }

            memcpy(kkey, data, 3);
            RC4InitWithKey(&rc, kkey, keylen+3); 
            for(s = 4; s < (framelen-24); s++) 
                data[s-4] = data[s] ^ step(&rc);

            if (doFCS(data, framelen - 28) == 0xdebb20e3) {
                f->frameControl&=~IEEE80211_WEP;
                h.caplen-=8;
                h.len-=8;
                pcap_dump((u_char*)pw,&h,x);
                decCount++;
            } else decError++;
        } else {
            pcap_dump((u_char*)pw,&h,x);
        }
    }    

    pcap_dump_close(pw);
    pcap_close(aPCapIN);    
    
    if (decCount>0&& decError>0) {
        NSBeginInformationalAlertSheet(
            NSLocalizedString(@"Decryption done.", "Decrypt error title"),
            OK, nil, nil, [self window], self, NULL, @selector(closeWindow:returnCode:contextInfo:), self, 
            [NSString stringWithFormat: 
                NSLocalizedString(@"KisMAC decrypted %u data frames. There were %u dropped frames, because of CRC errors.", "Decrypt dialog"), 
                decCount, decError]
            );
    } else if (decCount) {
        NSBeginInformationalAlertSheet(
            NSLocalizedString(@"Decryption done.", "Decrypt error title"),
            OK, nil, nil, [self window], self, NULL, @selector(closeWindow:returnCode:contextInfo:), self, 
            [NSString stringWithFormat: 
                NSLocalizedString(@"KisMAC decrypted all %u data frames.", "Decrypt dialog"), 
                decCount]
            );
    } else {
        NSBeginCriticalAlertSheet(
            NSLocalizedString(@"Decryption failed.", "Decrypt error title"),
            OK, nil, nil, [self window], Nil, Nil, Nil, Nil, 
            [NSString stringWithFormat: 
                NSLocalizedString(@"KisMAC dropped all %u data frames, because of CRC errors! This is most likely because you entered a wrong password.", "Decrypt dialog"), 
                decError]
            );
    }

    return;
error1:
    pcap_close(aPCapIN);
}

- (void)closeWindow:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [[self window] performClose:self];
}

- (IBAction)cancelAction:(id)sender {
    [[self window] performClose:sender];
}

- (IBAction)otherFile:(id)sender {
    NSOpenPanel *OP;
    NSSavePanel *SP;
    if (sender == _newInFile) {
        OP = [NSOpenPanel openPanel];
        [OP setAllowsMultipleSelection:NO];
        [OP setCanChooseFiles:YES];
        [OP setCanChooseDirectories:NO];
        if ([OP runModalForTypes:nil]==NSOKButton) {
            [_inFile setStringValue:[OP filename]];
        }
    } else {
        SP = [NSSavePanel savePanel];
        [SP setCanSelectHiddenExtension:YES];
        [SP setTreatsFilePackagesAsDirectories:NO];
        if ([SP runModal]==NSFileHandlingPanelOKButton) {
            [_outFile setStringValue:[SP filename]];
        }
    }
}


#pragma mark Fade Out Code

- (BOOL)windowShouldClose:(id)sender 
{
    // Set up our timer to periodically call the fade: method.
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES];
    return NO;
}

- (void)fade:(NSTimer *)timer {
    if ([[self window] alphaValue] > 0.0) {
        // If window is still partially opaque, reduce its opacity.
        [[self window] setAlphaValue:[[self window] alphaValue] - 0.2];
    } else {
        // Otherwise, if window is completely transparent, destroy the timer and close the window.
        [timer invalidate];
        [timer release];
        
        [[self window] close];
        
        // Make the window fully opaque again for next time.
        [[self window] setAlphaValue:1.0];
    }
}

@end
