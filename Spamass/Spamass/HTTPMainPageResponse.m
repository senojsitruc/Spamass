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

@interface HTTPMainPageResponse ()
{
	BOOL mIsDone;
	NSUInteger mResultCount;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, weak) HTTPConnection *connection;
@property (readwrite, assign) NSUInteger theOffset;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@end

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
