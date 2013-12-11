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
#import "NSString+Additions.h"
#import "GCDAsyncSocket.h"
#import "HTTPMainPageResponse.h"
#import "HTTPEmailSearchResponse.h"
#import "HTTPEmailViewResponse.h"

@interface HTTPSpamassResponse ()
@end

@implementation HTTPSpamassResponse

/**
 *
 *
 */
+ (NSObject<HTTPResponse> *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	DLog(@"filePath='%@'", filePath);
	
	@try {
		if ([filePath hasPrefix:@"/s?"])
			return [HTTPEmailSearchResponse responseWithPath:filePath forConnection:(HTTPConnection *)connection];
		else if ([filePath hasPrefix:@"/v?"])
			return [HTTPEmailViewResponse responseWithPath:filePath forConnection:(HTTPConnection *)connection];
		else
			return [HTTPMainPageResponse responseWithPath:filePath forConnection:(HTTPConnection *)connection];
	}
	@catch (NSException *e) {
		DLog(@"name = %@", [e name]);
		DLog(@"reason = %@", [e reason]);
		DLog(@"userInfo = %@", [e userInfo]);
		DLog(@"%@", [e callStackSymbols]);
	}
}





#pragma mark - Helpers

/**
 *
 *
 */
- (NSDictionary *)parseCgiParams:(NSString *)filePath
{
	NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
	NSArray *pairs = [[filePath substringFromIndex:3] componentsSeparatedByString:@"&"];
	
	for (NSString *pair in pairs) {
		NSArray *parts = [pair componentsSeparatedByString:@"="];
		if (parts.count == 2)
			[args setObject:[[parts objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[parts objectAtIndex:0] lowercaseString]];
	}
	
	return args;
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
