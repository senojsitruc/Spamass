//
//  NSThread+BlocksAdditions.h
//  Get
//
//  Created by Adam Preble on 5/27/10.
//  Copyright 2010 Nexidia. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NGThreadBlock : NSObject
{
@public
	void (^mBlock)();
}
@end

@interface NSThread (BlocksAdditions)
- (void)performBlock:(void (^)())block;
- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait;
- (void)performAfterDelay:(NSTimeInterval)delay block:(void (^)())block;
+ (void)performBlockInBackground:(void (^)())block;

+ (NSThread *)detachNewThreadBlock:(void (^)())block;
- (id)initWithBlock:(void (^)())block;

@end
