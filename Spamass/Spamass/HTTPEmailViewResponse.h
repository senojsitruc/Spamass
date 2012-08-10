//
//  HTTPEmailViewResponse.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.10.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPSpamassResponse.h"

@class HTTPConnection;

@interface HTTPEmailViewResponse : HTTPSpamassResponse

+ (HTTPEmailViewResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection;

@end
