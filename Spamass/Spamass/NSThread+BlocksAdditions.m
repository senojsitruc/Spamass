//
//  NSThread+BlocksAdditions.m
//  Get
//
//  Created by Adam Preble on 5/27/10.
//  Copyright 2010 Nexidia. All rights reserved.
//

#import "NSThread+BlocksAdditions.h"

@implementation NGThreadBlock
- (void)dealloc
{
	[mBlock release];
	[super dealloc];
}

@end

@implementation NSThread (BlocksAdditions)

- (void)performBlock:(void (^)())block
{
	if ([[NSThread currentThread] isEqual:self])
		block();
	else
		[self performBlock:block waitUntilDone:NO];
}

- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait
{
    [NSThread performSelector:@selector(ng_runBlock:)
                 onThread:self
               withObject:[block copy]
            waitUntilDone:wait];
}

- (void)performAfterDelay:(NSTimeInterval)delay block:(void (^)())theBlock
{
	void (^block)() = [theBlock copy];
	[self performBlock:^{
		[NSThread performSelector:@selector(ng_runBlock:)
					   withObject:block
					   afterDelay:delay];
	}];
}

+ (void)ng_runBlock:(void (^)())block
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	block();
	[block release];
	[pool release];
}

+ (void)performBlockInBackground:(void (^)())block
{
	[NSThread performSelectorInBackground:@selector(ng_runBlock:)
						   withObject:[block copy]];
	 
}

/**
 *
 *
 */
+ (NSThread *)detachNewThreadBlock:(void (^)())block
{
	NSThread *thread = [[[NSThread alloc] initWithBlock:block] autorelease];
	
	[thread start];
	
	return thread;
}

/**
 * Detaches and returns a new thread with the given block. You can use the returned thread object
 * to determine when the thread has finished executing, for instance. Also, we're going to set the
 * stack size of this new thread to something sane.
 */
- (id)initWithBlock:(void (^)())block
{
	NGThreadBlock *threadBlock = [[[NGThreadBlock alloc] init] autorelease];
	
	threadBlock->mBlock = [block copy];
	
	self = [self initWithTarget:self selector:@selector(ng_runThreadBlock:) object:threadBlock];
	
	if (self) {
		[self setStackSize:1024 * 1024 * 8];
	}
	
	return self;
}


/**
 *
 *
 */
- (void)ng_runThreadBlock:(NGThreadBlock *)threadBlock
{
	threadBlock->mBlock();
}

@end
