//
//  HTTPEmailViewResponse.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.10.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "HTTPEmailViewResponse.h"
#import "HTTPConnection.h"
#import "SMAppDelegate.h"
#import "SMEmail.h"
#import "NSString+Additions.h"
#import "GCDAsyncSocket.h"

@implementation HTTPEmailViewResponse

+ (HTTPEmailViewResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	HTTPEmailViewResponse *response = [[HTTPEmailViewResponse alloc] init];
	NSDictionary *args = [response parseCgiParams:filePath];
	NSString *address=nil, *socketId=nil, *serial=nil;
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	NSLog(@"%s.. request='%@'", __PRETTY_FUNCTION__, filePath);
	
	{
		NSArray *parts = [[args objectForKey:@"e"] componentsSeparatedByString:@"__"];
		
		if (parts.count != 3) {
			NSMutableString *output = [[NSMutableString alloc] init];
			[output appendString:@"<html><head><title>Hello.</title></head><body>"];
			[output appendString:@"Not a valid request. [101]"];
			[output appendString:@"</body></html>\r\n"];
			[response.dataBuffer appendBytes:output.UTF8String length:output.length];
			response->mIsDone = TRUE;
			return response;
		}
		
		address = [parts objectAtIndex:0];
		socketId = [parts objectAtIndex:1];
		serial = [parts objectAtIndex:2];
	}
	
	NSString *emailPath = [SMAppDelegate pathWithSocketId:socketId serial:serial mkdir:FALSE];
	NSData *emailData = [NSData dataWithContentsOfFile:emailPath];
	
	if (!emailData || emailData.length == 0) {
		NSLog(@"%s.. socketId=%@, serial=%@, emailPath='%@'", __PRETTY_FUNCTION__, socketId, serial, emailPath);
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>Hello.</title></head><body>"];
		[output appendString:@"Not a valid request. [102]"];
		[output appendString:@"</body></html>\r\n"];
		[response.dataBuffer appendBytes:output.UTF8String length:output.length];
		response->mIsDone = TRUE;
		return response;
	}
	
	// search result header
	{
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>"];
		[output appendString:address];
		[output appendString:@"</title></head><body>"];
		[output appendString:@"<table border=1 cellspacing=0 cellspacing=0><tr><td>"];
		[output appendString:@"<table border=0 cellpadding=3 cellspacing=10><tr><td><pre>"];
		[output appendString:[[NSString alloc] initWithBytes:emailData.bytes length:emailData.length encoding:NSUTF8StringEncoding]];
		[output appendString:@"</pre></td></tr></table>\r\n"];
		[output appendString:@"</td></tr></table>\r\n"];
		[output appendString:@"</body></html>\r\n"];
		[response.dataBuffer appendBytes:output.UTF8String length:output.length];
	}
	
	response->mIsDone = TRUE;
	
	return response;
}

@end
