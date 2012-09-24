//
//  TrafficController.m
//  KisMAC
//
//  Created by mick on Thu Jul 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <BIGL/BIGL.h>
#import "WaveScanner.h"
#import "KisMACNotifications.h"
#import "TrafficController.h"

@implementation TrafficController

- (id)init {
    self = [super init];
    if (!self)
        return nil;

    justSwitchedDataType = NO;
    currentMode = trafficData;

    _grid = [[BIGLLineView alloc] initWithLines:[NSArray array]];
    [_grid setLocation: NSMakePoint(30,30)];
    [_grid setLineWidth:0.5];
    _gridFrame = [[BIGLLineView alloc] initWithLines:[NSArray array]];
    [_gridFrame setLineWidth:2];

    _zeroLabel = [[BIGLTextView alloc] init];
    [_zeroLabel setLocation: NSMakePoint(15,8)];
    _maxLabel = [[BIGLTextView alloc] init];
    _curLabel = [[BIGLTextView alloc] init];
    _legend = [[BIGLImageView alloc] init];
    [_legend setVisible:NO];
    
    _graphs = [[NSMutableArray array] retain];
    
    [self setBackgroundColor:[NSColor blackColor]];
    [self setGridColor:[NSColor colorWithCalibratedRed:96.0/255.0 green:123.0/255.0 blue:173.0/255.0 alpha:1]];

    zoomLock = [[NSLock alloc] init];
    
    vScale = 0;
    dvScale = 0;
    maxLength = 0;
    gridNeedsRedrawn = NO;
    
    /* color wheel permutation */
    NSMutableArray *tempColor = [NSMutableArray array];
    for (int x=0; x<=32; x++) {
        float hue=0.0;
        for (int i=2;i<=32;i=i*2) {
            if ( (x % i) >= (i/2) ) hue += 1.0/ (float)i;
        }
        [tempColor addObject:[NSColor colorWithDeviceHue:hue saturation:1 brightness:1 alpha:0.9]];
    }
    colorArray = [[NSArray arrayWithArray:tempColor] retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings:) name:KisMACUserDefaultsChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resized:) name:BIGLMainViewResized object:nil];
    [self updateSettings:nil];
    
    return self;
}

-(void)awakeFromNib {
    [_modeButton selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"GraphMode"]];
    [_intervalButton selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"GraphTimeInterval"]];

    // default to 30-second interval
    scanInterval = [_scanner scanInterval];
    maxLength = (int)(30.0 / scanInterval);
    [self setTimeLength:_intervalButton];
    [self setCurrentMode:_modeButton];
    
    [_view addSubView:_grid];
    [_grid addSubView:_gridFrame];
    [_view addSubView:_zeroLabel];
    [_view addSubView:_maxLabel];
    [_view addSubView:_curLabel];
    [_view addSubView:_legend];
   
    [self updateGraph];
}

#pragma mark -

- (void)setBackgroundColor:(NSColor *)newColor {
   [_view setBackgroundColor:newColor];
}

- (void)setGridColor:(NSColor *)newColor {
    [_grid      setColor:newColor];
    [_gridFrame setColor:newColor];
}

- (IBAction)setTimeLength:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:[sender indexOfSelectedItem] forKey:@"GraphTimeInterval"];

    maxLength = (int)ceil([[sender selectedItem] tag] / scanInterval);
    gridNeedsRedrawn = YES;
    
    [self performSelectorOnMainThread:@selector(resized:) withObject:nil waitUntilDone:YES];
}

- (IBAction)setCurrentMode:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:[sender indexOfSelectedItem] forKey:@"GraphMode"];

    justSwitchedDataType = YES;
    currentMode = [sender indexOfSelectedItem];
    if(currentMode != trafficData && currentMode != packetData && currentMode != signalData)
        currentMode = trafficData;

    [self performSelectorOnMainThread:@selector(resized:) withObject:nil waitUntilDone:YES];
}

- (void)updateSettings:(NSNotification*)note {
    NSUserDefaults *sets = [NSUserDefaults standardUserDefaults];
    _legendMode = 0;
    
    if ([[sets objectForKey:@"TrafficViewShowSSID"]  intValue] == 1) _legendMode++;
    if ([[sets objectForKey:@"TrafficViewShowBSSID"] intValue] == 1) _legendMode+=2;
}

- (void)outputTIFFTo:(NSString*)file {
    NSRect rect = [_view frame];
    rect.origin = NSZeroPoint;
    
    [[_view dataWithTIFFInsideRect:rect] writeToFile:file atomically:YES];
}

- (void)resized:(NSNotification*)note {
    [self updateGraph];
}

#pragma mark -

- (void)updateDataForRect:(NSRect)rect {
    int i, current;
    unsigned int j;
    
    [WaveHelper secureReplace:&allNets withObject:[_container allNets]];
    
    // order networks by signal value
    switch(currentMode) {
        case trafficData:
            [allNets sortUsingSelector:@selector(compareRecentTrafficTo:)];
            break;
        case packetData:
            [allNets sortUsingSelector:@selector(compareRecentPacketsTo:)];
            break;
        case signalData:
            [allNets sortUsingSelector:@selector(compareRecentSignalTo:)];
            break;
    }

    // setup graph rect with nice margins
    graphRect = rect;
    graphRect.origin.x = 30;
    graphRect.origin.y = 30;
    graphRect.size.width -= 60;
    graphRect.size.height -= 60;

    length = [_scanner graphLength];
    if(length > maxLength) {
        offset = length - maxLength;
        length = maxLength;
    }
    else {
        offset = 0;
    }

    aMaximum=0;
    memset(buffer,0,MAX_YIELD_SIZE * sizeof(int));

    // find the biggest point on our graph
    for (i = 0 ; i < length ; i++) {
        current = 0;
        for(j = 0 ; j < [allNets count] ; j++) {
            switch(currentMode) {
                case trafficData:
                    current += [(WaveNet*)[allNets objectAtIndex:j] graphData].trafficData[i + offset];
                    break;
                case packetData:
                    current += [(WaveNet*)[allNets objectAtIndex:j] graphData].packetData[i + offset];
                    break;
                case signalData:
                    current += [(WaveNet*)[allNets objectAtIndex:j] graphData].signalData[i + offset];
                    break;
            }
        }
        buffer[i] = current;
        if (current > aMaximum)
            aMaximum = current;
    }
    

    // a horizontal line for every 5 seconds
    stepx = graphRect.size.width / maxLength / scanInterval * 5;

    dvScale = graphRect.size.height / (1.2 * aMaximum);
    if(!vScale)
        vScale = dvScale;
    if(dvScale != vScale) {
        if(justSwitchedDataType) {
            justSwitchedDataType = NO;
            vScale = dvScale;
        }
        else {
            [NSThread detachNewThreadSelector:@selector(zoomThread:) toTarget:self withObject:nil];
        }
    }

    // a vertical line for every 512 bytes
    stepy = 40 * vScale * scanInterval;
}

- (void)updateGraph {
    // do some math...
    [self updateDataForRect:[_view frame]];
    
    // do the drawing...
    [self drawGridInRect:graphRect];
    [self drawGraphInRect:graphRect];
    [self drawGridLabelForRect:[_view frame]];
    [self drawLegendForRect:graphRect];
    [_view setNeedsDisplay:YES];
}

- (void)drawGridInRect:(NSRect)rect {
    static float lastVScale = 0.0;
    static NSRect lastRect = NSZeroRect;
    NSMutableArray *a;
    int i = 0;
    int count = 0;
    int multiple = 0;
    float curY, curX;
    
    if(lastVScale == vScale && NSEqualRects(lastRect,rect)
       && !gridNeedsRedrawn) {
        gridNeedsRedrawn = NO;
        return;
    }

    // if we get here, then the grid needs to be redrawn
    lastVScale = vScale;
    lastRect = rect;
    a = [NSMutableArray array];
    
    count = (int)ceil(rect.size.height / stepy);
    if(count >= 20) {
        multiple = 2;		// show a line each 1kb
        if(count >= 100)
            multiple = 10;	// show a line very 5kb
        if(count >= 200)
            multiple = 20;	// show a line very 10kb
    }
    for(i = 0 ; i * stepy < rect.size.height ; i++) {
        if(multiple && i % multiple)
            continue;
        curY = (i * stepy);
        if (curY < rect.size.height) {
            [a addObject:[NSNumber numberWithFloat:0.5]];
            [a addObject:[NSNumber numberWithFloat:curY]];
            [a addObject:[NSNumber numberWithFloat:rect.size.width]];
            [a addObject:[NSNumber numberWithFloat:curY]];
        }
    }
    multiple = 0;

    count = (int)ceil(rect.size.width / stepx);
    if(count >= 60) {
        multiple = 12;		// show a line each minute
        if(count >= 720)
            multiple = 120;	// show a line very 5 minutes
    }
    for (i = 0 ; i < count ; i++) {
        if(multiple && i % multiple)
            continue;
        curX = (i * stepx);
        if (curX < rect.size.width) {
            [a addObject:[NSNumber numberWithFloat:curX]];
            [a addObject:[NSNumber numberWithFloat:0.5]];
            [a addObject:[NSNumber numberWithFloat:curX]];
            [a addObject:[NSNumber numberWithFloat:rect.size.height]];
        }
    }
    [_grid setLines:a];
    
    a = [NSMutableArray array];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:rect.size.height+1]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:rect.size.height+1]];
    [a addObject:[NSNumber numberWithFloat:rect.size.width+2]];
    [a addObject:[NSNumber numberWithFloat:rect.size.height+1]];
    [a addObject:[NSNumber numberWithFloat:rect.size.width+2]];
    [a addObject:[NSNumber numberWithFloat:rect.size.height+1]];
    [a addObject:[NSNumber numberWithFloat:rect.size.width+2]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:rect.size.width+2]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [a addObject:[NSNumber numberWithFloat:-1]];
    [_gridFrame setLines:a];
}

- (void)drawGraphInRect:(NSRect)rect {
    int i, *ptr;
    unsigned int n;
    BIGLGraphView *curView;
    NSMutableArray *a;
    
    while ([_graphs count] < [allNets count]) {
        [_graphs addObject:[[BIGLGraphView alloc] init]];
        [[_graphs lastObject] setLocation:NSMakePoint(31,31)];
        [(BIGLSubView*)[_graphs lastObject] setVisible:YES];
        [_view addSubView:[_graphs lastObject]];
        [[_graphs lastObject] autorelease];
    }
    
    for(n = 0 ; n < [allNets count] ; n++) {
        WaveNet* net = [allNets objectAtIndex:n];
        float width = rect.size.width;
        float height;
        
        switch(currentMode) {
            case trafficData:
                ptr = [net graphData].trafficData;
                break;
            case packetData:
                ptr = [net graphData].packetData;
                break;
            case signalData:
                ptr = [net graphData].signalData;
                break;
            default:
                ptr = [net graphData].trafficData;
        }
        
        if([[NSDate date] timeIntervalSinceDate:[net lastSeenDate]] >= (maxLength * scanInterval)) {
            [allNets removeObjectAtIndex:n];
            n--;
            continue;
        }
        
        curView = [_graphs objectAtIndex:n];
        a = [NSMutableArray arrayWithCapacity:length];
        stepx=(rect.size.width) / maxLength;
        
        for(i = 0 ; i < length ; i++) {
            height = buffer[i] * vScale;
            if (height > rect.size.height) height = rect.size.height;
            [a addObject:[NSNumber numberWithFloat:width - (((float)(length - i)) * stepx)]];
            [a addObject:[NSNumber numberWithFloat:height]];
        }
        i--;
        
        [a addObject:[NSNumber numberWithFloat:width]];
        [a addObject:[NSNumber numberWithFloat:buffer[i] * vScale]];
        [curView setGraph:a];
        
        if (![net graphColor])
        {
            static int colorCount = 0;
            [net setGraphColor:[colorArray objectAtIndex:colorCount % [colorArray count]]];
            colorCount++;
        }
        
        NSColor *c = [[net graphColor] copy];
        [curView setColor:[c autorelease]];

        for(i = 0 ; i < length ; i++) {
            buffer[i] -= ptr[i + offset];
        }
    }
    
    for(;n < [_graphs count]; n++)
        [(BIGLSubView*)[_graphs objectAtIndex:n] setVisible:NO];
        
}

- (void)drawGridLabelForRect:(NSRect)rect {
    // draws the text, giving a numerical value to the graph
    unsigned int j;
    int current = 0, max = 0;
    NSMutableDictionary* attrs = [[[NSMutableDictionary alloc] init] autorelease];
    NSFont* textFont = [NSFont fontWithName:@"Monaco" size:12];
    NSString *zeroStr, *currentStr, *maxStr;

    if(length) {
        for(j = 0 ; j < [allNets count] ; j++) {
            switch(currentMode) {
                case trafficData:
                    current += (int)([(WaveNet*)[allNets objectAtIndex:j] graphData].trafficData[length - 2 + offset]  / scanInterval);
                    break;
                case packetData:
                    current += (int)([(WaveNet*)[allNets objectAtIndex:j] graphData].packetData[length - 2 + offset]);
                    break;
                case signalData:
                    current += (int)([(WaveNet*)[allNets objectAtIndex:j] graphData].signalData[length - 2 + offset]);
                    break;
            }
        }
    }

    if (currentMode==trafficData)
        max = (int)(aMaximum * 1.1 / scanInterval);
    else
        max = (int)(aMaximum * 1.1);
    
    [attrs setObject:textFont forKey:NSFontAttributeName];
    [attrs setObject:[NSColor colorWithCalibratedRed:96.0/255.0 green:123.0/255.0 blue:173.0/255.0 alpha:1] forKey:NSForegroundColorAttributeName];

    switch(currentMode) {
        case trafficData:
            zeroStr = @"0 bps";
            currentStr = [self stringForBytes:current];
            maxStr = [self stringForBytes:max];
            break;
        case packetData:
            zeroStr = @"0 packets";
            currentStr = [self stringForPackets:current];
            maxStr = [self stringForPackets:max];
            break;            
        case signalData:
            zeroStr = @"0 signal";
            currentStr = [self stringForSignal:current];
            maxStr = [self stringForSignal:max];
            break;            
        default:
            zeroStr = @"0 bps";
            currentStr = [self stringForBytes:current];
            maxStr = [self stringForBytes:max];
            break;
    }
    
    
    [_zeroLabel setString:zeroStr    withAttributes:attrs];
    [_maxLabel  setString:maxStr     withAttributes:attrs];
    [_curLabel  setString:currentStr withAttributes:attrs];
    
    [_maxLabel setLocation: NSMakePoint(15,rect.size.height - 5 - [textFont boundingRectForFont].size.height)];
    [_curLabel setLocation: NSMakePoint(rect.size.width - 30 - [currentStr sizeWithAttributes:attrs].width, 8)];
}

- (void)drawLegendForRect:(NSRect)rect {
    NSImage * image;
    unsigned int i;
    float width = 0, height = 0;
    NSBezierPath* legendPath = [[NSBezierPath alloc] init];
    NSMutableDictionary* attrs = [[[NSMutableDictionary alloc] init] autorelease];
    NSFont* textFont = [NSFont fontWithName:@"Monaco" size:12];
    
    if(_legendMode == 0 || ![allNets count]) {
        [_legend setVisible:NO];
        return;
    }
    
    [_legend setVisible:YES];
    [attrs setObject:textFont forKey:NSFontAttributeName];

    for(i = 0 ; i < [allNets count] ; i++) {
        NSSize size = [[self stringForNetwork:[allNets objectAtIndex:i]] sizeWithAttributes:attrs];
        if(size.width > width) width = size.width;
        if(size.height > height) height = size.height;
    }
    width += 20;
    height = [allNets count] * (height + 5) + 5;
    
    image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image lockFocus];

    [legendPath appendBezierPathWithRect:NSMakeRect(0, 0, width, height)];
    [[[NSColor blackColor] colorWithAlphaComponent:0.80] set];
    [legendPath fill];
    [[[NSColor whiteColor] colorWithAlphaComponent:0.10] set];
    [legendPath fill];
    [[[NSColor whiteColor] colorWithAlphaComponent:0.25] set];
    [NSBezierPath setDefaultLineWidth:2];
    [legendPath stroke];
    [legendPath release];

    for(i = 0 ; i < [allNets count] ; i++) 
    {
        WaveNet * net = (WaveNet*)[allNets objectAtIndex:i];
        //make sure there is a color
        if (![net graphColor])
        {
            static int colorCount = 0;
            [net setGraphColor:[colorArray objectAtIndex:colorCount % [colorArray count]]];
            colorCount++;
        }
        [attrs setObject:[net graphColor] forKey: NSForegroundColorAttributeName];
        [[self stringForNetwork:[allNets objectAtIndex:i]] drawAtPoint:NSMakePoint(9, height - ((i+1) * 20)) withAttributes:attrs];
    }
    [image unlockFocus];

    [_legend setImage: image];
    [_legend setLocation: NSMakePoint(31, rect.size.height - height + 30)];
    
    [image release];
}

#pragma mark -

- (NSString*)stringForNetwork:(WaveNet*)net {
    switch (_legendMode) {
        case 1:
            return [net SSID];
        case 2:
            return [net BSSID];
        case 3:
            return [NSString stringWithFormat:@"%@, %@", [net BSSID],[net SSID]];
    }
    return nil;
}

- (NSString*)stringForBytes:(int)bytes {
    if(bytes < 1024)
        return [NSString stringWithFormat:@"%d bps",bytes];
    else
        return [NSString stringWithFormat:@"%.2f kbps",(float)bytes / 1024];
}

- (NSString*)stringForPackets:(int)bytes {
    return [NSString stringWithFormat:@"%d %@", bytes, NSLocalizedString(@"packets/sec", "label of traffic view")];
}

- (NSString*)stringForSignal:(int)bytes {
    return [NSString stringWithFormat:@"%d %@", bytes, NSLocalizedString(@"signal", "label of traffic view")];
}

#pragma mark -


- (void)zoomThread:(id)object {
    NSAutoreleasePool* subpool = [[NSAutoreleasePool alloc] init];

    int i;
    int fps = 30;
    int frames = (int)floor((float)fps * scanInterval);
    float delta = (dvScale - vScale) / (float)frames;

    if([zoomLock tryLock]) {
        //NSLog(@"ZOOMING: frames = %d, delta = %f",frames,delta);    
        for(i = 0 ; i < frames ; i++) {
            vScale += delta;
            [self performSelectorOnMainThread:@selector(resized:) withObject:nil waitUntilDone:YES];
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:scanInterval / frames]];
        }
        vScale = dvScale;
        [zoomLock unlock];
    }
    else {
        //NSLog(@"ZOOM LOCK IS LOCKED!");
    }
    
    [subpool release];
}


#pragma mark -

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [colorArray release];
    [allNets release];
    
    [_grid release];
    
    [_graphs release];
    [_grid release];
    [_gridFrame release];
    [_zeroLabel release];
    [_curLabel release];
    [_maxLabel release];
    [_legend release];
    
    [zoomLock release];
    [super dealloc];
}

@end
