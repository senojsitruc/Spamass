//
//  HTTPMainPageResponse.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "HTTPMainPageResponse.h"
#import "HTTPConnection.h"
#import "SMAppDelegate.h"
#import "SMEmail.h"
#import "NSString+Additions.h"
#import "GCDAsyncSocket.h"

@implementation HTTPMainPageResponse

/**
 *
 *
 */
+ (HTTPMainPageResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	HTTPMainPageResponse *response = [[HTTPMainPageResponse alloc] init];
	
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = TRUE;
	
	NSMutableString *output = [[NSMutableString alloc] init];
	[output appendString:@"<html><head><title>"];
	[output appendString:@"Hello."];
	[output appendString:@"</title></head><body>"];
	[output appendString:@"<form action=s method=get>"];
	[output appendString:@"<input type=text size=40 placeholder=\"example@spamass.net\" name=\"e\" />"];
	[output appendString:@"<input type=submit value=\"View\" />"];
	[output appendString:@"</form><br><br>"];
	[output appendString:@"Please do not spam me at:<br>\n<br>\n"];
	
	NSString *addr = [connection->asyncSocket connectedHost];
	uint16_t port = [connection->asyncSocket connectedPort];
	
	for (NSUInteger i = 0; i < 20; ++i) {
		NSString *email = [SMAppDelegate randomEmailAddress];
		[output appendString:@"&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"mailto:"];
		[output appendString:email];
		[output appendString:@"\">"];
		[output appendString:email];
		[output appendString:@"</a><br>\n"];
		NSLog(@"%s.. %@ for %@:%hu", __PRETTY_FUNCTION__, email, addr, port);
	}
	
	[output appendString:@"<br>\nThank you for your cooperation."];
	[output appendString:@"<br>\n<br>\n"];
	[output appendString:[SMAppDelegate randomWords]];
	[output appendString:@"</body></html>"];
	[response.dataBuffer appendBytes:output.UTF8String length:[output lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	
	return response;
}

@end
