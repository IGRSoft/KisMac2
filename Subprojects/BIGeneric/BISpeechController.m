//
//  BISpeechController.m
//  BIGeneric
//
//  Created by mick on Tue Jul 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BISpeechController.h"
#import "BINSExtensions.h"

@implementation BISpeechController

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _speakThread = NO;
    _speakLock = [[NSLock alloc] init];
    _sentenceQueue = [[NSMutableArray array] retain];
    NewSpeechChannel(NULL, &_curSpeechChannel);
    NSAssert(_curSpeechChannel, @"Could not obtain speech channel!");

    return self;
}

//says a specific sentence
- (void)doSpeakSentence:(const char*)cSentence withVoice:(int)voice {
    VoiceSpec theVoiceSpec;
    
    NS_DURING
    if (voice==1) {
        _selectedVoiceCreator = 0;
    } else {
        GetIndVoice(voice-2, &theVoiceSpec);
        _selectedVoiceCreator = theVoiceSpec.creator;
        _selectedVoiceID = theVoiceSpec.id;
        
        NSAssert(SetSpeechInfo(_curSpeechChannel, soCurrentVoice, &theVoiceSpec) != incompatibleVoice, @"Voice is not compatible");
    }
    
    SpeakText(_curSpeechChannel, cSentence, strlen(cSentence));
    NS_HANDLER
        NSLog(@"Error raised while trying to speak");
    NS_ENDHANDLER
}

//tries every 0.1 seconds to speak something from the queue
- (void)speakThread:(id)obj {
    NSString* s;
    int i;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    _speakThread = YES;
    
    while(YES) {
        [_speakLock lock];
        
        if ([_sentenceQueue count] == 0) break;
        
        if (SpeechBusySystemWide()==0) {
            s = [_sentenceQueue objectAtIndex:0];
            i = [[_sentenceQueue objectAtIndex:1] intValue];
            [self doSpeakSentence:[s UTF8String] withVoice:i];
            [_sentenceQueue removeObjectAtIndex:1];
            [_sentenceQueue removeObjectAtIndex:0];
        }
        
        [_speakLock unlock];
        [NSThread sleep:0.2];
    }
    
    _speakThread = NO;
    [_speakLock unlock];
    [pool drain];
}

//adds a sentence tp the speak queue
- (void)addSentenceToQueue:(const char*)cSentence withVoice:(int)voice {
    [_sentenceQueue addObject:[NSString stringWithUTF8String: cSentence]];
    [_sentenceQueue addObject:[NSNumber numberWithInt: voice]];
    
    if (!_speakThread) [NSThread detachNewThreadSelector:@selector(speakThread:) toTarget:self withObject:nil];
}

//tries to speak something. if it does not work => put it to the queue
- (void)speakSentence:(const char*)cSentence withVoice:(int)voice {
    [_speakLock lock];

    if (SpeechBusySystemWide() || [_sentenceQueue count] != 0) [self addSentenceToQueue:cSentence withVoice:voice];
    else [self doSpeakSentence:cSentence withVoice:voice];

    [_speakLock unlock];
}

#pragma mark -

- (void) dealloc {
    DisposeSpeechChannel(_curSpeechChannel);
    _curSpeechChannel = NULL;
 
    [_sentenceQueue release];
    [_speakLock release];
    
    [super dealloc];
}
@end
