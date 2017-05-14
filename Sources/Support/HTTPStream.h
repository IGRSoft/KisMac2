/*
 
 File:			HTTPStream.h
 Program:		KisMAC
 Author:		Michael Roßberg
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

@interface HTTPStream : NSObject
{
    NSURL *_url;
    NSDictionary *_postVariables;
    BOOL _inProgress;
    BOOL _reportErrors;
    NSInteger  _errorCode;
    
    CFReadStreamRef _stream;
}

- (id)initWithURL:(NSURL*)url andPostVariables:(NSDictionary*)postVariables reportErrors:(BOOL)reportErrors;

- (void)setReportErrors:(BOOL)reportErrors;
- (BOOL)setURL:(NSURL*) url;
- (BOOL)setPostVariables:(NSDictionary*)postVariables;
- (BOOL)execute;
- (BOOL)working;
- (NSInteger)errorCode;
@end
