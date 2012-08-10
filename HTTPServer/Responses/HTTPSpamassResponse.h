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
{
	BOOL mIsDone;
	NSUInteger mResultCount;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, weak) HTTPConnection *connection;
@property (readwrite, assign) NSUInteger theOffset;
@property (nonatomic, strong) NSMutableData *dataBuffer;

+ (NSObject<HTTPResponse> *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection;

- (NSDictionary *)parseCgiParams:(NSString *)filePath;

@end
