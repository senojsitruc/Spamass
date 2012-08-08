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
	response->mIsDone = TRUE;
	
	filePath = [filePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
	
	NSLog(@"%s.. filePath='%@'", __PRETTY_FUNCTION__, filePath);
	
	[SMAppDelegate emailsForAddress:filePath withBlock:^ (SMEmail *email) {
		NSLog(@"%s.. got an email!", __PRETTY_FUNCTION__);
		
		if (!email)
			response->mIsDone = TRUE;
		else {
			[response.dataBuffer appendBytes:email.socketId.UTF8String length:email.socketId.length];
			[response.dataBuffer appendBytes:"\r\n" length:2];
		}
		
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
	return mIsDone;
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
- (void)connectionDidClose
{
	
	// TODO: after this occurs, we must not use our mConnection pointer any longer
	
}

@end
