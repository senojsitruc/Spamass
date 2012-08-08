//
//  HTTPSpamassResponse.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

@class HTTPConnection;

@interface HTTPSpamassResponse : NSObject <HTTPResponse>

+ (HTTPSpamassResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection;

@end
