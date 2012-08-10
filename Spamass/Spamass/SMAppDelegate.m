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
#import "SMMapViewController.h"
#import <emailz_public.h>
#import <dispatch/dispatch.h>
#import <sys/stat.h>

static SMAppDelegate *gAppDelegate;
static NSArray *gMaleNames;
static NSArray *gFemaleNames;
static NSArray *gLastNames;
static NSArray *gWords;

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
 *
 *
 */
+ (void)initialize
{
	NSString *maleNamesPath = [[NSBundle mainBundle] pathForResource:@"other/firstnames-male" ofType:@"txt"];
	NSString *femaleNamesPath = [[NSBundle mainBundle] pathForResource:@"other/firstnames-female" ofType:@"txt"];
	NSString *lastNamesPath = [[NSBundle mainBundle] pathForResource:@"other/lastnames" ofType:@"txt"];
	NSString *wordsPath = [[NSBundle mainBundle] pathForResource:@"other/words" ofType:@"txt"];
	
	// male names
	{
		NSArray *names = [[NSString stringWithContentsOfFile:maleNamesPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];;
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
		
		for (NSString *name in names)
			[tmp setObject:name forKey:name];
		
		gMaleNames = [tmp allKeys];
	}
	
	// female names
	{
		NSArray *names = [[NSString stringWithContentsOfFile:femaleNamesPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];;
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
		
		for (NSString *name in names)
			[tmp setObject:name forKey:name];
		
		gFemaleNames = [tmp allKeys];
	}
	
	// last names
	{
		NSArray *names = [[NSString stringWithContentsOfFile:lastNamesPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];;
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
		
		for (NSString *name in names)
			[tmp setObject:name forKey:name];
		
		gLastNames = [tmp allKeys];
	}
	
	// words
	{
		NSArray *words = [[NSString stringWithContentsOfFile:wordsPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];;
		NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
		
		for (NSString *word in words)
			[tmp setObject:word forKey:word];
		
		gWords = [tmp allKeys];
	}
}

/**
 * FROM:<curtis@symphonicsys.com> SIZE=12345
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
	
	NSArray *parts = [arg componentsSeparatedByCharactersInSet:mEmailSplitSet];
	
	for (NSString *part in parts) {
		if (part.length != 0) {
			socket.email.sender = part;
			break;
		}
	}
	
	//socket.email.sender = [arg stringByTrimmingCharactersInSet:mEmailSplitSet];
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
- (void)handleData:(NSData *)data withSocket:(SMSocket *)socket
{
	SMEmail *email = socket.email;
	NSString *arg = [[NSString alloc] initWithCString:data.bytes encoding:NSUTF8StringEncoding];
	NSMutableDictionary *headers = email.headers;
	
	[email.data appendData:data];
	
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
	NSString *emailPath = nil;
	
	[mDb setString:subject forKey:[prefix stringByAppendingString:@"subject"]];
	[mDb setString:email.sender forKey:[prefix stringByAppendingString:@"sender"]];
	[mDb setString:[[NSNumber numberWithInteger:email.dataSize] stringValue] forKey:[prefix stringByAppendingString:@"size"]];
	
	[mDb setString:@"1" forKey:[[email.recipients objectAtIndex:0] stringByAppendingString:@"__99999999999999999-999.999.999.999-99999__999999"]];
	
	{
		char path_str[1000] = { 0 };
		char *path_ptr = path_str;
		const char *socketid = email.socketId.UTF8String;
		
		strcpy(path_ptr, "/Volumes/StoreX/Spamass/Record/");
		path_ptr = path_str + strlen(path_str);
		
		// yyyy
		*path_ptr = socketid[0]; path_ptr++;
		*path_ptr = socketid[1]; path_ptr++;
		*path_ptr = socketid[2]; path_ptr++;
		*path_ptr = socketid[3]; path_ptr++;
		*path_ptr = '/';     path_ptr++;
		mkdir(path_str, S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO | S_IXOTH);
		
		// mm
		*path_ptr = socketid[4]; path_ptr++;
		*path_ptr = socketid[5]; path_ptr++;
		*path_ptr = '/';     path_ptr++;
		mkdir(path_str, S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO | S_IXOTH);
		
		// dd
		*path_ptr = socketid[6]; path_ptr++;
		*path_ptr = socketid[7]; path_ptr++;
		*path_ptr = '/';     path_ptr++;
		mkdir(path_str, S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO | S_IXOTH);
		
		// hh
		*path_ptr = socketid[8]; path_ptr++;
		*path_ptr = socketid[9]; path_ptr++;
		*path_ptr = '/';     path_ptr++;
		mkdir(path_str, S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO | S_IXOTH);
		
		// mm
		*path_ptr = socketid[10]; path_ptr++;
		*path_ptr = socketid[11]; path_ptr++;
		*path_ptr = '/';     path_ptr++;
		mkdir(path_str, S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO | S_IXOTH);
		
		// ss
		*path_ptr = socketid[12]; path_ptr++;
		*path_ptr = socketid[13]; path_ptr++;
		*path_ptr = '/';     path_ptr++;
		mkdir(path_str, S_IRWXU | S_IRGRP | S_IXGRP | S_IRWXO | S_IXOTH);
		
		// file
		strcpy(path_ptr, socketid);
		path_ptr += strlen(socketid);
		
		// .socket
		strcpy(path_ptr, ".email");
		path_ptr += 7;
		
		emailPath = [[NSString alloc] initWithCString:path_str encoding:NSUTF8StringEncoding];
	}
	
	if (emailPath)
		[email.data writeToFile:emailPath atomically:TRUE];
	
	NSLog(@"%s.. email is done! [sender='%@', size=%lu, subject='%@', path='%@']", __PRETTY_FUNCTION__, email.sender, email.dataSize, subject, emailPath);
	
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
	
	/*
	{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mDb];
		NSString *key = nil;
		
		while (nil != (key = [iter nextKey])) {
			NSLog(@"%s.. key='%@', value='%@'", __PRETTY_FUNCTION__, key, [mDb stringForKey:key]);
		}
	}
	*/
	
	mHttpQueue = dispatch_queue_create("net.spamass.spamass-http", DISPATCH_QUEUE_CONCURRENT);
	
	[NSThread detachNewThreadSelector:@selector(startHttp) toTarget:self withObject:nil];
	
	mEmailSplitSet = [NSCharacterSet characterSetWithCharactersInString:@" <>,\r\n"];
	
	mEmailz = emailz_create();
	emailz_record_enable(mEmailz, true, "/Volumes/StoreX/Spamass/Record/");
	
	//
	// smtp handler
	//
	mSmtpHandler = [^ (emailz_t emailz, void *_context, emailz_smtp_command_t command, unsigned char *_arg) {
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
		SMSocket *socket = (__bridge SMSocket *)context;
		
		if (!done)
			[self handleData:[NSData dataWithBytes:data length:datalen] withSocket:socket];
		else
			[self handleEmailWithSocket:socket];
	} copy];
	
	//
	// socket handler
	//
	emailz_set_socket_handler(mEmailz, ^ (emailz_t emailz, emailz_socket_t socket, emailz_socket_state_t state, void **context) {
		if (EMAILZ_SOCKET_STATE_OPEN == state) {
			SMSocket *socketObj = [[SMSocket alloc] init];
			socketObj.socketId = [NSString stringWithCString:emailz_socket_get_name(socket) encoding:NSUTF8StringEncoding];
			emailz_socket_set_smtp_handler(socket, mSmtpHandler);
			emailz_socket_set_data_handler(socket, mDataHandler);
			*context = (__bridge_retained void *)socketObj;
		}
		else if (EMAILZ_SOCKET_STATE_CLOSE == state) {
			(void)(__bridge_transfer SMSocket *)*context;
			// TODO: update socket record in db for socket stats?
		}
	});
	
	emailz_start(mEmailz);
	
	// map
	{
		SMMapViewController *mapController = [[SMMapViewController alloc] init];
		self.window.contentView = mapController.view;
		self.window.minSize = NSMakeSize(1200, 1200);
		self.window.maxSize = NSMakeSize(1200, 1200);
		
		[mapController setMarkerAtLongitude:-84. latitude:33.];
	}
	
}

/**
 *
 *
 */
+ (void)emailsForAddress:(NSString *)address withBlock:(BOOL (^)(SMEmail*))handler
{
	[gAppDelegate emailsForAddress:address withBlock:handler];
}

/**
 *
 *
 */
- (void)emailsForAddress:(NSString *)address withBlock:(BOOL (^)(SMEmail*))handler
{
	handler = [handler copy];
	
	dispatch_async(mHttpQueue, ^{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mDb];
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
					if (!handler(email))
						break;
					email = nil;
				}
				
				if (!email) {
					email = [[SMEmail alloc] init];
					email.socketId = partSocket;
					email.serial = partSerial;
					[email.recipients addObject:partAddress];
				}
				
				NSString *value = [iter valueAsString];
				
				if ([partField isEqualToString:@"sender"])
					email.sender = value;
				else if ([partField isEqualToString:@"size"])
					email.dataSize = [value integerValue];
				else
					[email.headers setObject:[iter valueAsString] forKey:partField];
			}
			
			if (email)
				handler(email);
		}
		
		handler(nil);
	});
}

/**
 *
 *
 */
+ (NSString *)randomEmailAddress
{
	NSArray *firstNames = (random()%2) ? gMaleNames : gFemaleNames;
	NSArray *lastNames = gLastNames;
	NSMutableString *email = [[NSMutableString alloc] init];
	BOOL dot=FALSE, dash=FALSE;
	
	switch (random()%3) {
		case 0:
			dot = TRUE;
			break;
		case 1:
			dash = TRUE;
			break;
		case 2:
			break;
	}
	
	[email appendString:[firstNames objectAtIndex:(random()%firstNames.count)]];
	
	if (dot)
		[email appendString:@"."];
	else if (dash)
		[email appendString:@"-"];
	
	if (random()%2) {
		[email appendString:[firstNames objectAtIndex:(random()%firstNames.count)]];
		
		if (dot)
			[email appendString:@"."];
		else if (dash)
			[email appendString:@"-"];
	}
	
	[email appendString:[lastNames objectAtIndex:(random()%lastNames.count)]];
	[email appendString:@"@spamass.net"];
	
	if (random()%2)
		return [email lowercaseString];
	else
		return email;
}

/**
 *
 *
 */
+ (NSString *)randomWords
{
	NSArray *words = gWords;
	NSUInteger count = (random()%100);
	NSMutableString *string = [[NSMutableString alloc] init];
	
	for (NSUInteger i = 0; i < count; ++i) {
		[string appendString:[words objectAtIndex:(random()%words.count)]];
		[string appendString:@" "];
	}
	
	return string;
}

@end
