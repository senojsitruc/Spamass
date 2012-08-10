//
//  HTTPMainPageResponse.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPResponse.h"

@class HTTPConnection;

@interface HTTPMainPageResponse : NSObject <HTTPResponse>

+ (HTTPMainPageResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection;

@end
