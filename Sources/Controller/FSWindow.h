/*
 
 File:			FSWindow.h
 Program:		KisMAC
 Author:		Geordie Millar
                themacuser@gmail.com
 Changes:       Vitalii Parovishnyk(1012-2015)
 
 Description:	This file is a simple subclass of NSWindow, but overriding
                canBecomeKeyWindow so that borderless windows can accept
                keyDown events, so that the map view can use the arrow
                keys in fullscreen mode.
 
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

@interface FSWindow : NSWindow
{

}

- (BOOL)canBecomeKeyWindow;

@end
