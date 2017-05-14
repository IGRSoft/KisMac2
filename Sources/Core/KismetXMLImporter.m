/*
 
 File:			KismetXMLImporter.h
 Program:		KisMAC
 Author:		Geoffrey Kruse
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

#import "KismetXMLImporter.h"
#import "WaveContainer.h"
#import "WaveNet.h"

@implementation KismetXMLImporter

-(id) init {
    if (!(self = [super init])) return nil;
    return self;
}

- (void)parser:(NSXMLParser *)parser 
                didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict 
{  
    if (!currentNet) {
        currentNet = [[NSMutableDictionary alloc] init];
    }
    
    if([elementName isEqualToString:@"wireless-network"]){
        if([attributeDict[@"type"] isEqualToString:@"infrastructure"])
            [currentNet setValue: @"2" forKey:@"type"];
        else if([attributeDict[@"type"] isEqualToString:@"ad-hoc"])
            [currentNet setValue: @"1" forKey:@"type"];
        else if([attributeDict[@"type"] isEqualToString:@"probe"])
            [currentNet setValue: @"4" forKey:@"type"];
        if(attributeDict[@"first-time"]){
            [currentNet setValue: [NSDate dateWithNaturalLanguageString:(NSString*)attributeDict[@"first-time"]]
                                                          forKey:@"firstDate"];
}
        if(attributeDict[@"first-time"])
                [currentNet setValue: [NSDate dateWithNaturalLanguageString:attributeDict[@"last-time"]]
                                                              forKey:@"date"];
    }//first-time
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{

    if (!currentStringValue) {
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    if ([string characterAtIndex: 0] != '\n') {
        [currentStringValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (!currentNet) 
    {
        currentNet = [[NSMutableDictionary alloc] init];
    }
    
    if([elementName isEqualToString:@"SSID"])
    {
        //DBNSLog(@"Net Found SSID = %@", currentStringValue);
        [currentNet setValue: currentStringValue forKey:@"SSID"];
    }
    else if([elementName isEqualToString:@"BSSID"])
    {
        NSUInteger ID[6];
        sscanf([currentStringValue UTF8String],
               "%2lX:%2lX:%2lX:%2lX:%2lX:%2lX",
               &ID[0], &ID[1], &ID[2], &ID[3], &ID[4], &ID[5]);
        [currentNet setValue: [NSString stringWithFormat:@"%2lX%2lX%2lX%2lX%2lX%2lX",
                               ID[0], ID[1],ID[2], ID[3], ID[4], ID[5]] forKey:@"ID"];
        //DBNSLog(@"Net Found BSSID = %@", currentStringValue);
        [currentNet setValue: currentStringValue forKey:@"BSSID"];
    }
    else if([elementName isEqualToString:@"channel"])
    {
        [currentNet setValue: currentStringValue forKey:@"channel"];
    }
    else if([elementName isEqualToString:@"channel"])
    {
        [currentNet setValue: currentStringValue forKey:@"channel"];
    }
    else if([elementName isEqualToString:@"total"])
    {
        [currentNet setValue: currentStringValue forKey:@"packets"];
    }
    else if([elementName isEqualToString:@"data"])
    {
        [currentNet setValue: currentStringValue forKey:@"dataPackets"];
    }
    else if([elementName isEqualToString:@"datasize"])
    {
        [currentNet setValue: currentStringValue forKey:@"bytes"];
    }
    else if([elementName isEqualToString:@"encryption"])
    {
        if([currentStringValue isEqualToString: @"WEP"])
            [currentNet setValue: @"2" forKey:@"encryption"];
        else if([currentStringValue isEqualToString: @"WPA"])
            [currentNet setValue: @"4" forKey:@"encryption"];
        else if([currentStringValue isEqualToString: @"None"])
            [currentNet setValue: @"1" forKey:@"encryption"];
        else
            [currentNet setValue: @"0" forKey:@"encryption"];
    }
    else if([elementName isEqualToString:@"max-lat"])
    {
        [currentNet setValue: currentStringValue forKey:@"lat"];
    }
    else if([elementName isEqualToString:@"max-lon"])
    {
        [currentNet setValue: currentStringValue forKey:@"long"];
    }
    else if([elementName isEqualToString:@"max-alt"])
    {
        [currentNet setValue: currentStringValue forKey:@"elev"];
    }
    else if([elementName isEqualToString:@"wireless-network"])
    {
        //DBNSLog(@"End of Net Found");
        
        WaveNet* net = [[WaveNet alloc] initWithDataDictionary: currentNet];
        currentNet = nil;
        if (net)
        {
            [importedNets addObject:net];
        }else 
        {
            DBNSLog(@"Invalid Net!");
        }
    }

    currentStringValue = nil;
}


- (NSDictionary*)performKismetImport: (NSString *)filename withContainer:(WaveContainer*)container
{
    importedNets = [[NSMutableArray alloc] init];
    NSData * theData = [[NSData alloc] initWithContentsOfFile: filename];
	NSXMLParser * theParser = [[NSXMLParser alloc] initWithData: theData];
	[theParser setDelegate: self];
	if([theParser parse]){
        DBNSLog(@"Parsing succeded:\n");
        [container importData:importedNets];
    }
    
    else 
    {
        DBNSLog(@"Parsing Failed!!!\n");
        return nil;
       // hasValidData = NO;
    }
    
    importedNets = nil;
    theData = nil;
    theParser = nil;
    return currentNet;
}

@end
