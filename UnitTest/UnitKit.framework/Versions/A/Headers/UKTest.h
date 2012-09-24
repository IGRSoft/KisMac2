/*
 This source is part of UnitKit, a unit test framework for Mac OS X 
 development. You can find more information about UnitKit at:
 
 http://x180.net/Code/UnitKit
 
 Copyright (c)2004 James Duncan Davidson
 
 Contributions by Michael Milvich
 
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

/*!
 @protocol UKTest
 @abstract The marker protocol that indicates that a class should be picked up by a system.
 @discussion (description)
*/
@protocol UKTest

@end

#define UKPass() [[UKTestHandler handler] passInFile:__FILE__ line:__LINE__]

#define UKFail() [[UKTestHandler handler] failInFile:__FILE__ line:__LINE__]

#define UKTrue(condition) [[UKTestHandler handler] testTrue:(condition) inFile:__FILE__ line:__LINE__]

#define UKFalse(condition) [[UKTestHandler handler] testFalse:(condition) inFile:__FILE__ line:__LINE__]

#define UKNil(ref) [[UKTestHandler handler] testNil:(ref) inFile:__FILE__ line:__LINE__] 

#define UKNotNil(ref) [[UKTestHandler handler] testNotNil:(ref) inFile:__FILE__ line:__LINE__]

#define UKIntsEqual(a, b) [[UKTestHandler handler] testInt:(a) equalTo:(b) inFile:__FILE__ line:__LINE__]

#define UKIntsNotEqual(a, b) [[UKTestHandler handler] testInt:(a) notEqualTo:(b) inFile:__FILE__ line:__LINE__]

#define UKFloatsEqual(a, b, d) [[UKTestHandler handler] testFloat:(a) equalTo:(b) delta:(d) inFile:__FILE__ line:__LINE__]

#define UKFloatsNotEqual(a, b, d) [[UKTestHandler handler] testFloat:(a) notEqualTo:(b) delta:(d) inFile:__FILE__ line:__LINE__]

#define UKObjectsEqual(a, b) [[UKTestHandler handler] testObject:(a) equalTo:(b) inFile:__FILE__ line:__LINE__]

#define UKObjectsNotEqual(a, b) [[UKTestHandler handler] testObject:(a) notEqualTo:(b) inFile:__FILE__ line:__LINE__]

#define UKObjectsSame(a, b) [[UKTestHandler handler] testObject:(a) sameAs:(b) inFile:__FILE__ line:__LINE__]

#define UKObjectsNotSame(a, b) [[UKTestHandler handler] testObject:(a) notSameAs:(b) inFile:__FILE__ line:__LINE__]

#define UKStringsEqual(a, b) [[UKTestHandler handler] testString:(a) equalTo:(b) inFile:__FILE__ line:__LINE__]

#define UKStringsNotEqual(a, b) [[UKTestHandler handler] testString:(a) notEqualTo:(b) inFile:__FILE__ line:__LINE__]

#define UKStringContains(a, b) [[UKTestHandler handler] testString:(a) contains:(b) inFile:__FILE__ line:__LINE__]

#define UKStringDoesNotContain(a, b) [[UKTestHandler handler] testString:(a) doesNotContain:(b) inFile:__FILE__ line:__LINE__]

/*
 Exception testing macros contributed by Michael Milvich
 
 The exception testing macros get a bit more involved than all the other ones
 we have here because of the need for embedding the try-catch in the generated
 code. In addition, the statements are wrapped in a do{...}while(NO) block so
 that the generated code is sane even if the macro appears in a context like:
 
 if (someFlag)
    UKRaisesException(someExpression)
 else
    UKRaisesException(someOtherExpression)
 
 I would have never guessed this as I don't write if/else blocks without 
 braces, but Michael had the 411 on this when he wrote them.

 */

#define UKRaisesException(a) do{id p_exp = nil; @try { a; } @catch(id exp) { p_exp = exp; } [[UKTestHandler handler] raisesException:p_exp inFile:__FILE__ line:__LINE__]; } while(NO)

#define UKDoesNotRaiseException(a) do{id p_exp = nil; @try { a; } @catch(id exp) { p_exp = exp; } [[UKTestHandler handler] doesNotRaisesException:p_exp inFile:__FILE__ line:__LINE__]; } while(NO)

#define UKRaisesExceptionNamed(a, b) do{ id p_exp = nil; @try{ a; } @catch(id exp) { p_exp = exp;}[[UKTestHandler handler] raisesException:p_exp named:b inFile:__FILE__ line:__LINE__]; } while(NO)

#define UKRaisesExceptionClass(a, b) do{ id p_exp = nil; @try{ a; } @catch(id exp) { p_exp = exp;}[[UKTestHandler handler] raisesException:p_exp class:[b class] inFile:__FILE__ line:__LINE__]; } while(NO)
