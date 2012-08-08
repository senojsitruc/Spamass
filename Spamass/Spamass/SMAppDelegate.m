//
//  SMAppDelegate.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMAppDelegate.h"
#import "APLevelDB.h"
#import "SMEmail.h"
#import "SMSocket.h"
#import "HTTPServer.h"
#import <emailz_public.h>
#import <dispatch/dispatch.h>

static SMAppDelegate *gAppDelegate;

@interface SMAppDelegate ()
{
	APLevelDB *mDb;
	emailz_t mEmailz;
	HTTPServer *mHttpServer;
	dispatch_queue_t mHttpQueue;
	
	emailz_smtp_handler_t mSmtpHandler;
	emailz_data_handler_t mDataHandler;
	
	NSCharacterSet *mEmailSplitSet;
}
@end

@implementation SMAppDelegate

/**
 * FROM:<curtis@symphonicsys.com>
 *
 */
- (void)handleFrom:(NSString *)arg withSocket:(SMSocket *)socket
{
	socket.email = [[SMEmail alloc] init];
	socket.email.socketId = socket.socketId;
	socket.email.serial = [NSString stringWithFormat:@"%06lu", socket.emailCount];
	socket.email.isInHeaders = TRUE;
	
	if ([arg hasPrefix:@"FROM:"])
		arg = [arg substringFromIndex:5];
	
	socket.email.sender = [arg stringByTrimmingCharactersInSet:mEmailSplitSet];
}

/**
 * TO:<aaimes@me.com>
 *
 */
- (void)handleRcpt:(NSString *)arg withSocket:(SMSocket *)socket
{
	if ([arg hasPrefix:@"TO:"])
		arg = [arg substringFromIndex:3];
	
	NSArray *parts = [arg componentsSeparatedByCharactersInSet:mEmailSplitSet];
	
	for (NSString *part in parts) {
		if (part.length != 0)
			[socket.email addRecipient:part];
	}
}

/**
 *
 *
 */
- (void)handleData:(NSString *)arg withSocket:(SMSocket *)socket
{
	SMEmail *email = socket.email;
	NSMutableDictionary *headers = email.headers;
	
	if (email.isInHeaders) {
		if ([arg isEqualToString:@"\r\n"])
			email.isInHeaders = FALSE;
		else {
			NSString *name = email.lastHeader;
			NSString *value = nil;
			
			if (!name || 0 != [arg rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location) {
				NSRange range = [arg rangeOfString:@":"];
				if (range.location != NSNotFound) {
					email.lastHeader = name = [[[arg substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
					value = [arg substringFromIndex:range.location+1];
				}
				else {
					email.isInHeaders = FALSE;
					goto done;
				}
			}
			else
				value = arg;
			
			value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			//NSLog(@"%s.. name='%@', value='%@'", __PRETTY_FUNCTION__, name, value);
			
			NSObject *header = [headers objectForKey:name];
			
			if (!header) {
				header = value;
				[headers setObject:header forKey:name];
			}
			else if ([header isKindOfClass:[NSString class]]) {
				header = [NSMutableArray arrayWithObjects:header, value, nil];
				[headers setObject:header forKey:name];
			}
			else if ([header isKindOfClass:[NSMutableArray class]])
				[(NSMutableArray *)header addObject:value];
		}
	}
	else {
		//NSLog(@"%s.. email body: %@", __PRETTY_FUNCTION__, arg);
	}
	
done:
	socket.email.dataSize += arg.length;
}

/**
 * TODO: make sure there is at least one recipient before we call objectAtIndex(0); and then call
 *       for each recipient.
 *
 */
- (void)handleEmailWithSocket:(SMSocket *)socket
{
	SMEmail *email = socket.email;
	NSDictionary *headers = email.headers;
	NSString *prefix = email.dbprefix;
	NSString *subject = [headers objectForKey:@"subject"];
	
	[mDb setString:subject forKey:[prefix stringByAppendingString:@"subject"]];
	[mDb setString:email.sender forKey:[prefix stringByAppendingString:@"sender"]];
	[mDb setString:[[NSNumber numberWithInteger:email.dataSize] stringValue] forKey:[prefix stringByAppendingString:@"size"]];
	
	NSString *terminalKey = [[email.recipients objectAtIndex:0] stringByAppendingString:@"__99999999999999999-999.999.999.999-99999__999999"];
	NSLog(@"%s.. terminalKey='%@'", __PRETTY_FUNCTION__, terminalKey);
	
	[mDb setString:@"1" forKey:[[email.recipients objectAtIndex:0] stringByAppendingString:@"__99999999999999999-999.999.999.999-99999__999999"]];
	
	NSLog(@"%s.. email is done! [sender='%@', size=%lu, subject='%@']", __PRETTY_FUNCTION__, email.sender, email.dataSize, subject);
	
	socket.email = nil;
}

/**
 *
 *
 */
- (void)startHttp
{
	mHttpServer = [[HTTPServer alloc] init];
	[mHttpServer setPort:10080];
	[mHttpServer start:nil];
}

/**
 *
 *
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	gAppDelegate = self;
	
	if (nil == (mDb = [APLevelDB levelDBWithPath:@"/Users/cjones/Desktop/Spamass-Email.db" error:nil])) {
		NSLog(@"%s.. failed to open database!", __PRETTY_FUNCTION__);
		return;
	}
	
	{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mDb];
		NSString *key = nil;
		
		while (nil != (key = [iter nextKey])) {
			NSLog(@"%s.. key='%@', value='%@'", __PRETTY_FUNCTION__, key, [mDb stringForKey:key]);
		}
	}
	
	mHttpQueue = dispatch_queue_create("net.spamass.spamass-http", DISPATCH_QUEUE_CONCURRENT);
	
	[NSThread detachNewThreadSelector:@selector(startHttp) toTarget:self withObject:nil];
	
	mEmailSplitSet = [NSCharacterSet characterSetWithCharactersInString:@" <>,\r\n"];
	
	mEmailz = emailz_create();
	emailz_record_enable(mEmailz, false);
	
	//
	// smtp handler
	//
	mSmtpHandler = [^ (emailz_t emailz, void *_context, emailz_smtp_command_t command, unsigned char *_arg) {
		//NSLog(@"%s.. command=%d, arg=%s", __PRETTY_FUNCTION__, command, _arg);
		
		SMSocket *socket = (__bridge SMSocket *)_context;
		NSString *arg = [NSString stringWithCString:(char *)_arg encoding:NSUTF8StringEncoding];
		
		if (EMAILZ_SMTP_COMMAND_MAIL == command)
			[self handleFrom:arg withSocket:socket];
		
		else if (EMAILZ_SMTP_COMMAND_RCPT == command)
			[self handleRcpt:arg withSocket:socket];
	} copy];
	
	//
	// data handler
	//
	mDataHandler = [^ (emailz_t emailz, void *context, size_t datalen, const void *data, bool done) {
		//NSLog(@"%s.. datalen=%lu, data=%s", __PRETTY_FUNCTION__, datalen, (char *)data);
		
		SMSocket *socket = (__bridge SMSocket *)context;
		
		if (!done) {
			NSString *arg = [NSString stringWithCString:(char *)data encoding:NSUTF8StringEncoding];
			[self handleData:arg withSocket:socket];
		}
		else
			[self handleEmailWithSocket:socket];
	} copy];
	
	//
	// socket handler
	//
	emailz_set_socket_handler(mEmailz, ^ (emailz_t emailz, emailz_socket_t socket, emailz_socket_state_t state, void **context) {
		//NSLog(@"%s.. socket! [%d]", __PRETTY_FUNCTION__, state);
		
		if (EMAILZ_SOCKET_STATE_OPEN == state) {
			SMSocket *socketObj = [[SMSocket alloc] init];
			socketObj.socketId = [NSString stringWithCString:emailz_socket_get_name(socket) encoding:NSUTF8StringEncoding];
			emailz_socket_set_smtp_handler(socket, mSmtpHandler);
			emailz_socket_set_data_handler(socket, mDataHandler);
			*context = (__bridge_retained void *)socketObj;
		}
		else if (EMAILZ_SOCKET_STATE_CLOSE == state) {
			(void)(__bridge_transfer SMSocket *)*context;
			//SMSocket *socketObj = (__bridge_transfer SMSocket *)*context;
			// TODO: update socket record in db for socket stats?
		}
	});
	
	emailz_start(mEmailz);
}

/**
 *
 *
 */
+ (void)emailsForAddress:(NSString *)address withBlock:(void (^)(SMEmail*))handler
{
	[gAppDelegate emailsForAddress:address withBlock:handler];
}

/**
 *
 *
 */
- (void)emailsForAddress:(NSString *)address withBlock:(void (^)(SMEmail*))handler
{
	handler = [handler copy];
	
	dispatch_async(mHttpQueue, ^{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mDb];
//	NSString *prefix = [address stringByAppendingString:@"__"];
		SMEmail *email = nil;
		NSString *key;
		
		if ([iter seekToKey:[address stringByAppendingString:@"__99999999999999999-999.999.999.999-99999__999999"]]) {
			while ([(key = [iter prevKey]) hasPrefix:address]) {
				NSArray *parts = [key componentsSeparatedByString:@"__"];
				
				if ([parts count] != 4) {
					NSLog(@"%s.. invalid key! [%@]", __PRETTY_FUNCTION__, key);
					break;
				}
				
				NSString *partAddress = [parts objectAtIndex:0];
				NSString *partSocket = [parts objectAtIndex:1];
				NSString *partSerial = [parts objectAtIndex:2];
				NSString *partField = [parts objectAtIndex:3];
				
				if (![partAddress isEqualToString:address])
					break;
				
				if (email && (![email.socketId isEqualToString:partSocket] || ![email.serial isEqualToString:partSerial])) {
					handler(email);
					email = nil;
				}
				
				if (!email) {
					email = [[SMEmail alloc] init];
					email.socketId = partSocket;
					email.serial = partSerial;
				}
				
				[email.headers setObject:[iter valueAsString] forKey:partField];
			}
			
			if (email)
				handler(email);
		}
		
		handler(nil);
	});
}

@end