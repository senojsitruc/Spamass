//
//  SMSocket.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMEmail;

@interface SMSocket : NSObject

@property (nonatomic, strong) NSString *socketId;
@property (nonatomic, strong) SMEmail *email;
@property (readonly) NSUInteger emailCount;

@end
