//
//  HTTPMainPageResponse.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPSpamassResponse.h"

@class HTTPConnection;

@interface HTTPMainPageResponse : HTTPSpamassResponse

+ (HTTPMainPageResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection;

@end
