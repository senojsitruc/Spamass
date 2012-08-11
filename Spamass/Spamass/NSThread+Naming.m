//
//  NSThread+Naming.m
//  ScriptSync
//
//  Created by Adam Preble on 4/14/11.
//  Copyright 2011 Nexidia, Inc. All rights reserved.
//

#import "NSThread+Naming.h"
#import "pthread.h"

@implementation NSThread (Naming)

+ (void)cz_setCurrentThreadName:(NSString *)name
{
	if (name != nil)
		pthread_setname_np([name UTF8String]);
}

+ (void)cz_updateCurrentThreadName
{
	[NSThread cz_setCurrentThreadName:[[NSThread currentThread] name]];
}

@end



@implementation CZThread

- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread cz_updateCurrentThreadName];
	
	[super main];
	[pool drain];
}

@end