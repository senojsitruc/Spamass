//
//  SMSocket.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMSocket.h"
#import "SMEmail.h"

@interface SMSocket ()
{
	NSUInteger mEmailCount;
}
@end

@implementation SMSocket

@synthesize socketId = mSocketId;
@synthesize ipaddress = mIpAddress;
@synthesize email = mEmail;
@synthesize emailCount = mEmailCount;

/**
 *
 *
 */
- (SMEmail *)email
{
	return mEmail;
}

/**
 *
 *
 */
- (void)setEmail:(SMEmail *)email
{
	mEmail = email;
	mEmailCount += 1;
}

@end
