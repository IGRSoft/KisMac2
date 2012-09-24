//
//  HTTPStream.m
//  KisMAC
//
//  Created by mick on Mon Apr 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "HTTPStream.h"
#import "WaveHelper.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <netdb.h>

@implementation HTTPStream

- (id)init {
    _inProgress = NO;
    _errorCode = -1;
    
    self = [super init];
    return self;
}

- (id)initWithURL:(NSURL*)url andPostVariables:(NSDictionary*)postVariables reportErrors:(bool)reportErrors {
    self = [self init];
    if (!self) return Nil;
    
    NSParameterAssert(url);

    [self setURL: url];
    [self setPostVariables: postVariables];
    [self setReportErrors: reportErrors];
    [self execute];
    
    return self;
}

#pragma mark -

- (bool)setURL:(NSURL*) url {
    NSAssert(!_inProgress, @"Stream already working");
    
    [WaveHelper secureReplace:&_url withObject:url];
    return YES;
}

- (bool)setPostVariables:(NSDictionary*)postVariables {
    NSAssert(!_inProgress, @"Stream already working");
    
    [WaveHelper secureReplace:&_postVariables withObject:postVariables];
    return YES;
}

- (bool)working {
    return _inProgress;
}

- (int)errorCode {
    return _errorCode;
}

- (void)setReportErrors:(bool)reportErrors {
    _reportErrors = reportErrors;
}

- (bool)execute 
{
    NSEnumerator *e;
    NSString *var;
    CFIndex i;
    NSString *errstr;
    NSMutableString *topost;
    UInt8 buf[1024] = {0};
    CFHTTPMessageRef myMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    int sockd;
    struct sockaddr_in serv_name;
    int status;
    struct hostent *hp;
    u_long ip;
    
    NSAssert(!_inProgress, @"Stream already working");
    NSAssert(_url, @"URL not set");
    
    _inProgress = YES;

    // Get data for POST body
    topost = [NSMutableString string];
    e = [_postVariables keyEnumerator];
    
    while ((var = [e nextObject]) != nil)
        [topost appendFormat:@"&%@=%@", [WaveHelper urlEncodeString: var], [WaveHelper urlEncodeString: [_postVariables objectForKey:var]]];
    [topost deleteCharactersInRange:NSMakeRange(0, 1)];
    
    topost = [NSMutableString stringWithFormat:@"POST %@ HTTP/1.1\r\n"
            "Host: %@\r\n"
            "Connection: close\r\n"
            "Content-Type: application/x-www-form-urlencoded\r\n"
            "Content-Length: %d\r\n\r\n%@", 
                [_url path], [_url host], [topost length], topost];


    sockd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockd == -1)
    {
        errstr = @"Socket creation failed!";
        CFRelease(myMessage);
        goto error;
    }
    
    hp = gethostbyname([[_url host] UTF8String]);
    if (hp == NULL)
    {
        errstr = NSLocalizedString(@"Could not resolve Server", "Error for Crashreporter");
        CFRelease(myMessage);
        goto error1;
    }
    ip = *(int *)hp->h_addr_list[0];

    /* server address */ 
    serv_name.sin_family = AF_INET;
    serv_name.sin_addr.s_addr = ip;
    serv_name.sin_port = htons(80);
        
    /* connect to the server */
    status = connect(sockd, (struct sockaddr*)&serv_name, sizeof(serv_name));
    if (status == -1) {
        errstr = NSLocalizedString(@"Could not connect to server.", "Error for Crashreporter");
        CFRelease(myMessage);
        goto error1;
    }
    
    i = write(sockd, [topost UTF8String], [topost length]);
    if (i<=0)
    {
        CFRelease(myMessage);
        errstr = NSLocalizedString(@"Could Not Write", "Error for Crashreporter");
        goto error1;
    }
    
    while (!CFHTTPMessageIsHeaderComplete(myMessage))
    {
        i = read(sockd, buf, 1024);
        if (i<=0)
        {
            CFRelease(myMessage);
            errstr = NSLocalizedString(@"Could not read Response", "Error for Crashreporter");
            goto error1;
        
        }
        if (!CFHTTPMessageAppendBytes(myMessage, buf, i))
        {
            //Handle parsing error.
            CFRelease(myMessage);
            errstr = NSLocalizedString(@"Error reading response", "Error for Crashreporter");
            goto error1;
        }
    }
    
    _errorCode = CFHTTPMessageGetResponseStatusCode(myMessage);
    
    CFRelease(myMessage);
    close(sockd);
    
    _inProgress = NO;

    return YES;

error1: 
    close(sockd);
 
error:
    if (_reportErrors) NSBeginCriticalAlertSheet(
        NSLocalizedString(@"Transmittion failed.", "Title for Crashreporter"),
        OK, NULL, NULL, [WaveHelper mainWindow], self, NULL, NULL, NULL,
        [NSString stringWithFormat:@"%@: %@", 
        NSLocalizedString(@"The transmittion of the report failed because of the following error", "Dialog text for Crashreporter"), 
        errstr]);

    _errorCode = -1;
    _inProgress = NO;
    return NO;
}

#pragma mark -

- (void)dealloc {
    [WaveHelper secureRelease:&_url];
    [WaveHelper secureRelease:&_postVariables];
	[super dealloc];
}
@end
