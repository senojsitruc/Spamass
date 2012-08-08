//
//  SMEmail.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMEmail : NSObject

@property (nonatomic, strong) NSString *sender;
@property (nonatomic, strong) NSMutableArray *recipients;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *socketId;
@property (nonatomic, strong) NSString *serial;
@property (readwrite, assign) NSUInteger dataSize;
@property (nonatomic, strong) NSMutableDictionary *headers;
@property (nonatomic, strong) NSString *lastHeader;
@property (readwrite, assign) BOOL isInHeaders;

/**
 *
 */
- (NSString *)dbprefix;

/**
 *
 */
- (void)addRecipient:(NSString *)rcpt;

@end
