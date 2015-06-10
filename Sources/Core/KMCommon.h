/*
 
 File:			KMCommon.h
 Program:		KisMAC
 Author:		pr0gg3d
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

enum {
    KMRate1     = 0,
    KMRate2     = 1,
    KMRate5_5   = 2,
    KMRate11    = 3,
    KMRate6     = 4,
    KMRate9     = 5,
    KMRate12    = 6,
    KMRate18    = 7,
    KMRate24    = 8,
    KMRate36    = 9,
    KMRate48    = 10,
    KMRate54    = 11,
};

typedef UInt8 KMRate;

@interface KMCommon : NSObject {
    
}

@end
