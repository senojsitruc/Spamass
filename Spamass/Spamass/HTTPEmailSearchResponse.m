//
//  HTTPEmailSearchResponse.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "HTTPEmailSearchResponse.h"
#import "HTTPConnection.h"
#import "SMAppDelegate.h"
#import "SMEmail.h"
#import "NSString+Additions.h"
#import "GCDAsyncSocket.h"

@interface HTTPEmailSearchResponse ()
{
	BOOL mIsDone;
	NSUInteger mResultCount;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, weak) HTTPConnection *connection;
@property (readwrite, assign) NSUInteger theOffset;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@end

@implementation HTTPEmailSearchResponse

/**
 *
 *
 */
+ (HTTPEmailSearchResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	HTTPEmailSearchResponse *response = [[HTTPEmailSearchResponse alloc] init];
	NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
	__block NSUInteger emailCount = 0;
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	// parse cgi params
	{
		NSArray *pairs = [[filePath substringFromIndex:3] componentsSeparatedByString:@"&"];
		
		for (NSString *pair in pairs) {
			NSArray *parts = [pair componentsSeparatedByString:@"="];
			if (parts.count == 2)
				[args setObject:[[parts objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[parts objectAtIndex:0] lowercaseString]];
		}
	}
	
	NSLog(@"%s.. request='%@'", __PRETTY_FUNCTION__, filePath);
	
	NSString *emailAddress = [args objectForKey:@"e"];
	
	// make sure there was an email address in the query
	if (emailAddress.length == 0) {
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>Hello.</title></head><body>"];
		[output appendString:@"Not a valid request."];
		[output appendString:@"</body></html>\r\n"];
		[response.dataBuffer appendBytes:output.UTF8String length:output.length];
		response->mIsDone = TRUE;
		return response;
	}
	
	// search result header
	{
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>"];
		[output appendString:emailAddress];
		[output appendString:@"</title></head><body>"];
		[output appendString:@"<table border=1 cellspacing=0 cellspacing=0><tr><td>"];
		[output appendString:@"<table border=0 cellpadding=3 cellspacing=10><tr>"];
		[output appendString:@"<td>&nbsp;</td>"];
		[output appendString:@"<td>Sender</td>"];
		[output appendString:@"<td>Recipient</td>"];
		[output appendString:@"<td>Subject</td>"];
		[output appendString:@"<td>Size (bytes)</td>"];
		[output appendString:@"<td>Date (GMT)</td>"];
		[output appendString:@"<td>Remote</td>"];
		[output appendString:@"</tr>\r\n"];
		[response.dataBuffer appendBytes:output.UTF8String length:output.length];
	}
	
	[SMAppDelegate emailsForAddress:emailAddress withBlock:^ BOOL (SMEmail *email) {
		if (!response.connection) {
			NSLog(@"%s.. no more connection!", __PRETTY_FUNCTION__);
			return FALSE;
		}
		
		if (!email || emailCount++ >= 10) {
			response->mIsDone = TRUE;
			
			// search result footer
			{
				NSMutableString *output = [[NSMutableString alloc] init];
				[output appendString:@"</td></tr></table>\r\n"];
				[output appendString:@"</table></body></html>\r\n"];
				[response.dataBuffer appendBytes:output.UTF8String length:output.length];
			}
		}
		else {
			NSMutableString *output = [[NSMutableString alloc] init];
			NSArray *parts = [email.socketId componentsSeparatedByString:@"-"];
			NSString *color = nil;
			
			if ([parts count] != 3) {
				NSLog(@"%s.. invalid socketid [%@]", __PRETTY_FUNCTION__, email.socketId);
				return FALSE;
			}
			
			response->mResultCount += 1;
			
			if ((response->mResultCount % 2))
				color = @"Azure";
			else
				color = @"White";
			
			NSString *date = [parts objectAtIndex:0];
			NSString *addr = [parts objectAtIndex:1];
			NSString *port = [parts objectAtIndex:2];
			
			[output appendString:@"<tr bgcolor=\""];
			[output appendString:color];
			[output appendString:@"\">"];
			[output appendString:@"<td>"];
			[output appendString:[[NSNumber numberWithInteger:response->mResultCount] stringValue]];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:email.sender];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:[email.recipients objectAtIndex:0]];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:[email.headers objectForKey:@"subject"]];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:[[NSNumber numberWithInteger:email.dataSize] stringValue]];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:date];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:addr];
			[output appendString:@":"];
			[output appendString:port];
			[output appendString:@"</td>"];
			[output appendString:@"</tr>\r\n"];
			[response.dataBuffer appendBytes:output.UTF8String length:output.length];
		}
		
		[connection responseHasAvailableData:response];
		
		return TRUE;
	}];
	
	return response;
}





#pragma mark - HTTPResponse - Required

/**
 *
 *
 */
- (UInt64)contentLength
{
	return 0;
}

/**
 *
 *
 */
- (UInt64)offset
{
	return self.theOffset;
}

/**
 *
 *
 */
- (void)setOffset:(UInt64)offset
{
	self.theOffset = offset;
}

/**
 *
 *
 */
- (NSData *)readDataOfLength:(NSUInteger)length
{
	if (self.theOffset >= self.dataBuffer.length)
		return nil;
	
	length = MIN(length, self.dataBuffer.length - self.theOffset);
	NSData *data = [NSData dataWithBytes:self.dataBuffer.bytes+self.theOffset length:length];
	self.theOffset += length;
	
	return data;
}

/**
 *
 *
 */
- (BOOL)isDone
{
	return mIsDone && self.theOffset >= [self.dataBuffer length];
}





#pragma mark - HTTPResponse - Optional

/**
 *
 *
 */
- (BOOL)isChunked
{
	return TRUE;
}

/**
 *
 *
 */
- (BOOL)isAsynchronous
{
	return TRUE;
}

/**
 *
 *
 */
- (void)connectionDidClose
{
	self.connection = nil;
}

@end
