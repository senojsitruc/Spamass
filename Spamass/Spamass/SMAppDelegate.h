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
+ (SMAppDelegate *)sharedInstance;

/**
 *
 */
+ (void)emailsForAddress:(NSString *)address withBlock:(BOOL (^)(SMEmail*))handler;

/**
 *
 */
+ (NSString *)randomEmailAddress;
- (void)recordEmailAddress:(NSString *)email withOrigin:(NSString *)ipaddr;

/**
 *
 */
+ (NSString *)randomWords;

/**
 *
 */
+ (NSString *)pathForEmail:(SMEmail *)email mkdir:(BOOL)mkdir;
+ (NSString *)pathWithSocketId:(NSString *)socketId serial:(NSString *)serial mkdir:(BOOL)mkdir;

@end
