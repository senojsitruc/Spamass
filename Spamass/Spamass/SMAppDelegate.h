//
//  SMAppDelegate.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMEmail;

@interface SMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

/**
 *
 */
+ (void)emailsForAddress:(NSString *)address withBlock:(void (^)(SMEmail*))handler;

@end
