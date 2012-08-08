//
//  SMEmail.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMEmail.h"

@interface SMEmail ()
{
	NSMutableArray *mRecipients;
	NSMutableDictionary *mHeaders;
}
@end

@implementation SMEmail

@synthesize sender = mSender;
@synthesize recipients = mRecipients;
@synthesize subject = mSubject;
@synthesize socketId = mSocketId;
@synthesize serial = mSerial;
@synthesize dataSize = mDataSize;
@synthesize headers = mHeaders;
@synthesize lastHeader = mLastHeader;
@synthesize isInHeaders = mIsInHeaders;

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		mRecipients = [[NSMutableArray alloc] init];
		mHeaders = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/**
 * TODO: prefixForRecipientAtIndex:
 *
 */
- (NSString *)dbprefix
{
	NSMutableString *prefix = [[NSMutableString alloc] initWithCapacity:100];
	
	[prefix appendString:[mRecipients objectAtIndex:0]];
	[prefix appendString:@"__"];
	[prefix appendString:mSocketId];
	[prefix appendString:@"__"];
	[prefix appendString:mSerial];
	[prefix appendString:@"__"];
	
	return prefix;
}

/**
 *
 */
- (void)addRecipient:(NSString *)rcpt
{
	[mRecipients addObject:rcpt];
}

@end
