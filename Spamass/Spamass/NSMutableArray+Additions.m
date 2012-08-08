//
//  NSMutableArray+Additions.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.08.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "NSMutableArray+Additions.h"

@implementation NSMutableArray (Additions)

- (id)removeFirstObject
{
	if ([self count] == 0)
		return nil;
	
	NSObject *obj = [self objectAtIndex:0];
	[self removeObjectAtIndex:0];
	
	return obj;
}

@end
