//  ====================================================================== 	//
//  BLAuthentication.h														//
//  																		//
//  Last Modified on Tuesday April 24 2001									//
//  Copyright 2001 Ben Lachman												//
//																			//
//	Thanks to Brian R. Hill <http://personalpages.tds.net/~brian_hill/>		//
//  ====================================================================== 	//

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>

@interface BLAuthentication : NSObject 
{
	AuthorizationRef authorizationRef; 
}
// returns a shared instance of the class
+ sharedInstance;
// checks if user is authentcated forCommands
- (BOOL)isAuthenticated:(NSArray *)forCommands;
// authenticates user forCommands
- (BOOL)authenticate:(NSArray *)forCommands;
// deauthenticates user
- (void)deauthenticate;
// gets the pid forProcess
- (int)getPID:(NSString *)forProcess;
// executes pathToCommand with privileges
- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments;
// kills the process specified by commandFromPS
- (BOOL)killProcess:(NSString *)commandFromPS;
@end

// strings for notification center
extern NSString* BLAuthenticatedNotification;
extern NSString* BLDeauthenticatedNotification;




