/*
        File:			main.m
        Program:		KisMAC
		Author:			Geoffrey Kruse
		Description:	This file is part of KisMAC.

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

#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[])
{
    //setup our own logfile but save the old one for crash reporter
    NSString * path = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Logs/KisMAC.log"];
    NSString * oldLogPath = [NSString stringWithFormat:@"%@.%u", path, 1];
    NSError * error;
    
    [[NSFileManager defaultManager] moveItemAtPath:path toPath: oldLogPath error: &error];
    
    freopen([path UTF8String], "w+", stderr);
    
    return NSApplicationMain(argc, argv);
}
