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
	[output appendString:@"Free Throw-Away Email Address Server - Avoid the Spam"];
	[output appendString:@"</title></head><body>"];
	[output appendString:@"<table align=center width=500 border=0><tr><td><br/>"];
	[output appendString:@"If you need to provide an email address, use any <b><code>@spamass.net</code></b> address you want (no need to sign-up or register it) "];
	[output appendString:@"and then type that address into the form below to view the inbox. Please note that anyone can view the inbox."];
	[output appendString:@"</td></tr><table><br>\n"];
	[output appendString:@"<div align=center><form action=s method=get>"];
	[output appendString:@"<input type=text size=40 placeholder=\"example@spamass.net\" name=\"e\" />"];
	[output appendString:@"<input type=submit value=\"View\" />"];
	[output appendString:@"</form></div><br/><br/>"];
	
	{
		NSString *addr = [connection->asyncSocket connectedHost];
		uint16_t port = [connection->asyncSocket connectedPort];
		
		[output appendString:@"<br/><br/><br/><br/><br/><br/><br/><br/><br/>"];
		[output appendString:@"<div align=center>"];
		[output appendString:@"These are some random email addresses. Please ignore them.<br/>\n<br/>\n"];
		[output appendString:@"<table align=center border=0><tr>"];
		
		for (NSUInteger i = 0; i < 3; ++i) {
			NSString *email = [SMAppDelegate randomEmailAddress];
			[output appendString:@"<td><a href=\"mailto:"];
			[output appendString:email];
			[output appendString:@"\">"];
			[output appendString:email];
			[output appendString:@"</a></td>\n"];
			NSLog(@"%s.. %@ for %@:%hu", __PRETTY_FUNCTION__, email, addr, port);
			
			[[SMAppDelegate sharedInstance] recordEmailAddress:email withOrigin:addr];
		}
		
		[output appendString:@"</tr></table><br/>\n<br/>\n"];
		
		[output appendString:@"<center>And these are some random words. Please ignore them as well.</center><br/>\n"];
		[output appendString:@"<table align=center width=500 border=0><tr><td>\n"];
		[output appendString:[SMAppDelegate randomWords]];
		[output appendString:@"</td></tr></table></div>"];
		[output appendString:@"<br>\n<center>Thank you for your cooperation.</center>"];
		[output appendString:@"</body></html>"];
		[response.dataBuffer appendBytes:output.UTF8String length:[output lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return response;
}

@end
