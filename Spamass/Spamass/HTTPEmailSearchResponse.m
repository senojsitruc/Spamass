//
//  HTTPEmailSearchResponse.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "HTTPEmailSearchResponse.h"
#import "HTTPConnection.h"
#import "SMAppDelegate.h"
#import "SMEmail.h"
#import "NSString+Additions.h"
#import "GCDAsyncSocket.h"

@implementation HTTPEmailSearchResponse

/**
 *
 *
 */
+ (HTTPEmailSearchResponse *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	HTTPEmailSearchResponse *response = [[HTTPEmailSearchResponse alloc] init];
	NSDictionary *args = [response parseCgiParams:filePath];
	__block NSUInteger emailCount = 0;
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	DLog(@"request='%@'", filePath);
	
	NSString *emailAddress = [args objectForKey:@"e"];
	
	// make sure there was an email address in the query
	if (emailAddress.length == 0) {
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>Hello.</title></head><body>"];
		[output appendString:@"Not a valid request."];
		[output appendString:@"</body></html>\r\n"];
		[response.dataBuffer appendBytes:output.UTF8String length:output.length];
		response->mIsDone = TRUE;
		return response;
	}
	
	// search result header
	{
		NSMutableString *output = [[NSMutableString alloc] init];
		[output appendString:@"<html><head><title>"];
		[output appendString:emailAddress];
		[output appendString:@"</title></head><body>"];
		[output appendString:@"<table border=1 cellspacing=0 cellspacing=0><tr><td>"];
		[output appendString:@"<table border=0 cellpadding=3 cellspacing=10><tr>"];
		[output appendString:@"<td>&nbsp;</td>"];
		[output appendString:@"<td>Sender</td>"];
		[output appendString:@"<td>Recipient</td>"];
		[output appendString:@"<td>Subject</td>"];
		[output appendString:@"<td>Size (bytes)</td>"];
		[output appendString:@"<td>Date (GMT)</td>"];
		[output appendString:@"<td>Remote</td>"];
		[output appendString:@"</tr>\r\n"];
		[response.dataBuffer appendBytes:output.UTF8String length:output.length];
	}
	
	[SMAppDelegate emailsForAddress:emailAddress withBlock:^ BOOL (SMEmail *email) {
		if (!response.connection) {
			DLog(@"no more connection!");
			return FALSE;
		}
		
		if (!email || emailCount++ >= 10) {
			response->mIsDone = TRUE;
			
			// search result footer
			{
				NSMutableString *output = [[NSMutableString alloc] init];
				[output appendString:@"</td></tr></table>\r\n"];
				[output appendString:@"</table></body></html>\r\n"];
				[response.dataBuffer appendBytes:output.UTF8String length:output.length];
			}
		}
		else {
			NSMutableString *output = [[NSMutableString alloc] init];
			NSArray *parts = [email.socketId componentsSeparatedByString:@"-"];
			NSString *color = nil;
			
			if ([parts count] != 3) {
				DLog(@"invalid socketid [%@]", email.socketId);
				return FALSE;
			}
			
			response->mResultCount += 1;
			
			if ((response->mResultCount % 2))
				color = @"Azure";
			else
				color = @"White";
			
			NSString *date = parts[0];
			NSString *addr = parts[1];
			NSString *port = parts[2];
			
			date = [NSString stringWithFormat:@"%@-%@-%@ %@:%@:%@",
							[date substringWithRange:NSMakeRange(0,4)],
							[date substringWithRange:NSMakeRange(4,2)],
							[date substringWithRange:NSMakeRange(6,2)],
							[date substringWithRange:NSMakeRange(8,2)],
							[date substringWithRange:NSMakeRange(10,2)],
							[date substringWithRange:NSMakeRange(12,2)]
							];
			
			[output appendString:@"<tr bgcolor=\""];
			[output appendString:color];
			[output appendString:@"\">"];
			[output appendString:@"<td align=right><a href=\"v?e="];
			[output appendString:email.emailId];
			[output appendString:@"\">"];
			[output appendString:[[NSNumber numberWithInteger:response->mResultCount] stringValue]];
			[output appendString:@"</a></td>"];
			[output appendString:@"<td>"];
			[output appendString:email.sender];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:[email.recipients objectAtIndex:0]];
			[output appendString:@"</td>"];
			[output appendString:@"<td>"];
			[output appendString:[email.headers objectForKey:@"subject"]];
			[output appendString:@"</td>"];
			[output appendString:@"<td align=right>"];
			[output appendString:[[NSNumber numberWithInteger:email.dataSize] stringValue]];
			[output appendString:@"</td>"];
			[output appendString:@"<td><code>"];
			[output appendString:date]; // [date substringToIndex:14]];
			[output appendString:@"</code></td>"];
			[output appendString:@"<td><code>"];
			[output appendString:addr];
			[output appendString:@":"];
			[output appendString:port];
			[output appendString:@"</code></td>"];
			[output appendString:@"</tr>\r\n"];
			[response.dataBuffer appendBytes:output.UTF8String length:output.length];
		}
		
		[connection responseHasAvailableData:response];
		
		return TRUE;
	}];
	
	return response;
}

@end
