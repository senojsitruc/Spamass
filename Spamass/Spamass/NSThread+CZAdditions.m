//
//  NSThread+CZAdditions.m
//  ScriptSync
//
//  Created by Curtis Jones on 2011.04.29.
//  Copyright 2011 Nexidia, Inc. All rights reserved.
//

#import "NSThread+CZAdditions.h"

@implementation NSThread (NSThread_CZAdditions)

/**
 *
 *
 */
+ (void)printStackTrace
{
	NSArray *symbols = [NSThread callStackSymbols];
	
	for (NSString *symbol in symbols) {
		NSLog(@"%@", symbol);
	}
}

@end
