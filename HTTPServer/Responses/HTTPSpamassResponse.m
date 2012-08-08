//
//  HTTPSpamassResponse.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "HTTPSpamassResponse.h"
#import "HTTPConnection.h"
#import "SMAppDelegate.h"
#import "SMEmail.h"

@interface HTTPSpamassResponse ()
{
	BOOL mIsDone;
	NSUInteger mResultCount;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, weak) HTTPConnection *connection;
@property (readwrite, assign) NSUInteger theOffset;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@end

@implementation HTTPSpamassResponse

/**
 *
 *
 */
+ (HTTPSpamassResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	HTTPSpamassResponse *response = [[HTTPSpamassResponse alloc] init];
	
	response.filePath = [filePath copy];
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;;
	
	filePath = [filePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
	
	NSLog(@"%s.. filePath='%@'", __PRETTY_FUNCTION__, filePath);
	
	// search result header
	{
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>"];
		[output appendString:filePath];
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
	
	[SMAppDelegate emailsForAddress:filePath withBlock:^ (SMEmail *email) {
		if (!response.connection) {
			NSLog(@"%s.. no more connection!", __PRETTY_FUNCTION__);
			return;
		}
		
		if (!email) {
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
				return;
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
		
		NSLog(@"%s.. more data [offset=%lu, length=%lu]", __PRETTY_FUNCTION__, response.theOffset, response.dataBuffer.length);
		[connection responseHasAvailableData:response];
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
	NSLog(@"%s.. connection closed! [offset=%lu, length=%lu]", __PRETTY_FUNCTION__, self.theOffset, self.dataBuffer.length);
	self.connection = nil;
}

@end
