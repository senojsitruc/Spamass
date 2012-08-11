//
//  NSThread+Naming.h
//  ScriptSync
//
//  Created by Adam Preble on 4/14/11.
//  Copyright 2011 Nexidia, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSThread (Naming)

+ (void)cz_setCurrentThreadName:(NSString *)name;
+ (void)cz_updateCurrentThreadName;

@end


@interface CZThread : NSThread {
	
}
@end