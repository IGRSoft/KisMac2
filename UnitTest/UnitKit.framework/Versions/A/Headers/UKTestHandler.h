/*
 This source is part of UnitKit, a unit test framework for Mac OS X 
 development. You can find more information about UnitKit at:
 
 http://x180.net/Code/UnitKit
 
 Copyright (c)2004 James Duncan Davidson
 
 Contributions by Michael Milvich, Mark Dalrymple
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 The use of the Apache License does not indicate that this project is
 affiliated with the Apache Software Foundation.
 */

#import <Foundation/Foundation.h>
#import "UKRunner.h"

@interface UKTestHandler : NSObject {
    id delegate;
    int testsPassed;
    int testsFailed;
    BOOL quiet;
}

+ (UKTestHandler *)handler;

- (void) setDelegate:(id)aDelegate;
- (void) setQuiet:(BOOL)isQuiet;

- (void) reportStatus:(BOOL)cond inFile:(char *)filename line:(int)line message:(NSString *)msg;

- (void) reportWarning:(NSString *)message;

- (int) testsPassed;

- (int) testsFailed;

- (void) passInFile:(char *)filename line:(int)line;

- (void) failInFile:(char *)filename line:(int)line;

- (void) testTrue:(BOOL)cond inFile:(char *)filename line:(int)line;

- (void) testFalse:(BOOL)cond inFile:(char *)filename line:(int)line;

- (void) testNil:(void *)ref inFile:(char *)filename line:(int)line;

- (void) testNotNil:(void *)ref inFile:(char *)filename line:(int)line;

- (void) testInt:(int)a equalTo:(int)b inFile:(char *)filename line:(int)line;

- (void) testInt:(int)a notEqualTo:(int)b inFile:(char *)filename line:(int)line;

- (void) testFloat:(float)a equalTo:(float)b delta:(float)delta inFile:(char *)filename line:(int)line;

- (void) testFloat:(float)a notEqualTo:(float)b delta:(float)delta inFile:(char *)filename line:(int)line;

- (void) testObject:(id)a equalTo:(id)b inFile:(char *)filename line:(int)line;

- (void) testObject:(id)a notEqualTo:(id)b inFile:(char *)filename line:(int)line;

- (void) testObject:(id)a sameAs:(id)b inFile:(char *)filename line:(int)line;

- (void) testObject:(id)a notSameAs:(id)b inFile:(char *)filename line:(int)line;

- (void) testString:(NSString *)a equalTo:(NSString *)b inFile:(char *)filename line:(int)line;

- (void) testString:(NSString *)a notEqualTo:(NSString *)b inFile:(char *)filename line:(int)line;

- (void) testString:(NSString *)a contains:(NSString *)b inFile:(char *)filename line:(int)line;

- (void) testString:(NSString *)a doesNotContain:(NSString *)b inFile:(char *)filename line:(int)line;

- (void) raisesException:(NSException*)exception inFile:(char *)filename line:(int)line;

- (void) doesNotRaisesException:(NSException*)exception inFile:(char *)filename line:(int)line;

- (void) raisesException:(NSException*)exception named:(NSString*)expected inFile:(char *)filename line:(int)line;

- (void) raisesException:(id)raisedObject class:(Class)expectedClass inFile:(char *)filename line:(int)line;


@end

