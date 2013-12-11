//
//  SMGeocoder.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.11.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMGeocoder.h"
#import "APLevelDB.h"
#import "SBJsonParser.h"
#import <arpa/inet.h>
#import <stdint.h>

enum geocoder_iptype
{
	GEOCODER_IPTYPE_V4 = 4,
	GEOCODER_IPTYPE_V6 = 6
};

struct geocoder_region
{
	uint32_t addrbeg;
	uint32_t addrend;
	enum geocoder_iptype iptype;
	char code[3];
};

@interface SMGeocoder ()
{
	APLevelDB *_cacheDb;
	dispatch_queue_t _queue;
	
	NSUInteger _regionCount;
	APLevelDB *_regionDb;
	struct geocoder_region *_regions;
	
	NSMutableDictionary *_countryNamesByCode;
}
@end

@implementation SMGeocoder

/**
 *
 *
 */
- (id)initWithCacheDb:(APLevelDB *)cacheDb regionDb:(APLevelDB *)regionDb
{
	self = [super init];
	
	if (self) {
		_cacheDb = cacheDb;
		_regionDb = regionDb;
		_queue = dispatch_queue_create("net.spamass.geocoder", DISPATCH_QUEUE_CONCURRENT);
		
		{
			_countryNamesByCode = [[NSMutableDictionary alloc] init];
			
			NSString *path = [[NSBundle mainBundle] pathForResource:@"other/Country Codes" ofType:@"txt"];
			NSString *names = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
			NSArray *lines = [names componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
			
			[lines enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
				NSArray *parts = [(NSString *)obj componentsSeparatedByString:@"\t"];
				
				if (parts.count == 2)
					[_countryNamesByCode setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			}];
			
			DLog(@"loaded %lu country codes", _countryNamesByCode.count);
		}
		
		{
			APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:_regionDb];
			NSString *key = nil;
			_regionCount = 0;
			
			while (nil != (key = [iter nextKey]))
				_regionCount += 1;
		}
		
		if (_regionCount == 0)
			[self reloadRegions];
		
		_regions = (struct geocoder_region *)malloc(sizeof(struct geocoder_region) * _regionCount);
		memset(_regions, 0, sizeof(struct geocoder_region) * _regionCount);
		
		if (!_regions) {
			DLog(@"failed to malloc() regions!");
		}
		else {
			APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:_regionDb];
			struct geocoder_region *region = _regions;
			NSString *key = nil;
			NSUInteger regionCount = 0;
			
			@autoreleasepool {
				while (nil != (key = [iter nextKey]) && regionCount++ < _regionCount)
					memcpy(region++, [_regionDb dataForKey:key].bytes, sizeof(struct geocoder_region));
			}
			
			_regionCount = regionCount;
			
			DLog(@"loaded %lu region allocations", regionCount);
		}
	}
	
	return self;
}

/**
 *
 *
 */
- (void)reloadRegions
{
	DLog(@"reloading regions");
	
	_regionCount = 0;
	
	void (^parseFile)(NSString*, NSMutableArray*) = ^ (NSString *filePath, NSMutableArray *list) {
		@autoreleasepool {
			NSString *fileData = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
			NSArray *lines = [fileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
			
			if (0 == lines) {
				DLog(@"failed to read input file, %@", filePath);
				return;
			}
			
			for (NSString *line in lines) {
				NSArray *parts = [line componentsSeparatedByString:@"|"];
				
				if ([parts count] != 7)
					continue;
				
				if (FALSE == [[parts objectAtIndex:2] isEqualToString:@"ipv4"])
					continue;
				
				[list addObject:line];
			}
		}
	};
	
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSMutableArray *allocs = [[NSMutableArray alloc] init];
	
	parseFile([mainBundle pathForResource:@"other/delegated-afrinic-latest" ofType:@""], allocs);
	parseFile([mainBundle pathForResource:@"other/delegated-apnic-latest" ofType:@""], allocs);
	parseFile([mainBundle pathForResource:@"other/delegated-arin-latest" ofType:@""], allocs);
	parseFile([mainBundle pathForResource:@"other/delegated-lacnic-latest" ofType:@""], allocs);
	parseFile([mainBundle pathForResource:@"other/delegated-ripencc-latest" ofType:@""], allocs);
	
	[allocs enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSArray *parts = [(NSString *)obj componentsSeparatedByString:@"|"];
		struct geocoder_region region = { 0 };
		
		if (parts.count != 7)
			return;
		
//	NSString *rir   = parts[0];    // rir name
		NSString *code  = parts[1];    // country code
		NSString *type  = parts[2];    // ipv4 | ipv6
		NSString *addr  = parts[3];    // ip address
		NSString *size  = parts[4];    // number of addresses in allocation
//	NSString *date  = parts[5];    // allocation date
//	NSString *state = parts[6];    // assigned | allocated
		
		if (![type isEqualToString:@"ipv4"])
			return;
		
		if (code.length != 2)
			return;
		
		const char *codestr = code.UTF8String;
		
		region.addrbeg = ntohl(inet_addr(addr.UTF8String));
		region.addrend = region.addrbeg + (uint32_t)size.integerValue;
		region.iptype = GEOCODER_IPTYPE_V4;
		region.code[0] = codestr[0];
		region.code[1] = codestr[1];
		
		{
			NSArray *addrparts = [addr componentsSeparatedByString:@"."];
			addr = [NSString stringWithFormat:@"%03ld.%03ld.%03ld.%03ld",
							[addrparts[0] integerValue],
							[addrparts[1] integerValue],
							[addrparts[2] integerValue],
							[addrparts[3] integerValue]];
		}
		
		[_regionDb setData:[NSData dataWithBytes:&region length:sizeof(region)] forKey:addr];
		
		_regionCount += 1;
	}];
}

/**
 *
 *
 */
- (void)geocode:(NSString *)ipaddr handler:(SMGeocoderHandler)handler
{
	if (ipaddr.length == 0 || !handler)
		return;
	
	if ([ipaddr hasPrefix:@"10."] || [ipaddr hasPrefix:@"192.168."])
		return;
	
	dispatch_async(_queue, ^{
		[self __geocode:ipaddr handler:handler];
	});
}

/**
 *
 *
 */
- (NSString *)countryCodeForIPAddress:(NSString *)ipaddr
{
	NSInteger upper, lower, middle;
	struct geocoder_region *tmpalloc;
	uint32_t address = ntohl(inet_addr(ipaddr.UTF8String));
	
	if (0x7F == (address >> 24) || 0x0A == (address >> 24))
		return @"PN";
	
	if (_regionCount == 0)
		return nil;
	
	lower = 0;
	upper = _regionCount - 1;
	
	if (address < _regions[0].addrbeg)
		return 0;
	else if (address > _regions[_regionCount-1].addrend)
		return 0;
	
	while (1) {
		if (lower == upper) {
			tmpalloc = &_regions[lower];
			
			if (tmpalloc->addrbeg <= address && tmpalloc->addrend >= address)
				return [[NSString alloc] initWithBytes:tmpalloc->code length:2 encoding:NSUTF8StringEncoding];
			else
				return nil;
		}
		
		middle = lower + ((upper - lower) / 2);
		tmpalloc = &_regions[middle];
		
		if (tmpalloc->addrbeg > address)
			upper = middle - 1;
		else if (tmpalloc->addrend < address) {
			lower = middle + 1;
		}
		else
			return [[NSString alloc] initWithBytes:tmpalloc->code length:2 encoding:NSUTF8StringEncoding];
	}
	
	return nil;
}

/**
 *
 *
 */
- (NSString *)countryNameForIPAddress:(NSString *)ipaddr
{
	NSString *code = [self countryCodeForIPAddress:ipaddr];
	
	if (code.length == 0)
		return nil;
	else
		return [_countryNamesByCode objectForKey:code];
}

/**
 * First check our database. Then call hostip.info. If hostip.info can't help us, then look at the
 * country for the ip address assignment. Then call google. And don't forget to add a cache entry.
 */
- (void)__geocode:(NSString *)ipaddr handler:(SMGeocoderHandler)handler
{
	__block NSString *city=nil, *state=nil, *country=nil, *code=nil;
	double latitude=0., longitude=0.;
	
	// grab cached values from the database
	{
		NSString *lat=nil, *lon=nil;
		
		city = [_cacheDb stringForKey:[ipaddr stringByAppendingString:@"__city"]];
		state = [_cacheDb stringForKey:[ipaddr stringByAppendingString:@"__state"]];
		country = [_cacheDb stringForKey:[ipaddr stringByAppendingString:@"__country"]];
		code = [_cacheDb stringForKey:[ipaddr stringByAppendingString:@"__code"]];
		lat = [_cacheDb stringForKey:[ipaddr stringByAppendingString:@"__latitude"]];
		lon = [_cacheDb stringForKey:[ipaddr stringByAppendingString:@"__longitude"]];
		
		if (lat && lon) {
			handler([lat doubleValue], [lon doubleValue], city, state, country, code);
			return;
		}
	}
	
	// get geolocation information from hostip.info; this includes city, state, country and country
	// code. it does not include longitude and latitude, which is what we're really after.
	{
		NSError *error = nil;
		NSURL *url = [NSURL URLWithString:[@"http://api.hostip.info/get_html.php?ip=" stringByAppendingString:ipaddr]];
		NSURLRequest *requ = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
		NSData *data = [NSURLConnection sendSynchronousRequest:requ returningResponse:nil error:&error];
		
		if (!data) {
			DLog(@"no data for url [%@]", url);
			return;
		}
		
		NSString *text = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
		NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		[lines enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSString *line = (NSString *)obj;
			
			if (line.length == 0)
				return;
			
			NSArray *parts = [line componentsSeparatedByString:@": "];
			
			if (parts.count != 2) {
				DLog(@"invalid line [%@]", line);
				return;
			}
			
			NSString *label = parts[0];
			NSString *value = parts[1];
			
			if ([label isEqualToString:@"Country"])
				country = value;
			else if ([label isEqualToString:@"City"])
				city = value;
		}];
		
		if ([city.lowercaseString hasPrefix:@"(unknown city"])
			city = nil;
		
		if ([country.lowercaseString hasPrefix:@"(unknown country"])
			country = nil;
		
		// sepaarate the city from the state: "Atlanta, GA"
		{
			NSRange range = [city rangeOfString:@", "];
			
			if (NSNotFound != range.location) {
				state = [city substringFromIndex:range.location+2];
				city = [city substringToIndex:range.location];
			}
		}
		
		// sepaarate the country name from the country code: "United States (US)"
		{
			NSRange range = [country rangeOfString:@" ("];
			
			if (NSNotFound != range.location) {
				code = [country substringWithRange:NSMakeRange(range.location+2, 2)];
				country = [country substringToIndex:range.location];
			}
		}
	}
	
	// if we weren't able to get _any_ information on the ip address, use the ip addresse's country
	// allocation. it's not very specific, but it's better than "planet earth".
	if (country.length == 0) {
		code = [self countryCodeForIPAddress:ipaddr];
		country = [self countryNameForIPAddress:ipaddr];
		
		DLog(@"code=%@, country=%@", code, country);
	}
	
	// google maps - convert our city/state/country into a latitude and longitude
	{
		NSError *error = nil;
		NSMutableString *address = [[NSMutableString alloc] init];
		
		// form the address string we're going to geocode
		{
			if (city.length != 0) {
				[address appendString:city];
				[address appendString:@" "];
			}
			
			if (state.length != 0) {
				[address appendString:state];
				[address appendString:@" "];
			}
			
			if (country.length != 0)
				[address appendString:country];
			
			if (address.length == 0)
				return;
			
			//DLog(@"asking google for location [%@]", address);
		}
		
		NSURL *url = [NSURL URLWithString:[@"https://maps.googleapis.com/maps/api/geocode/json?sensor=true&address=" stringByAppendingString:[address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		NSURLRequest *requ = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
		NSData *data = [NSURLConnection sendSynchronousRequest:requ returningResponse:nil error:&error];
		
		if (!data) {
			DLog(@"no data for url [%@]", url);
			return;
		}
		
		NSDictionary *info = [[[SBJsonParser alloc] init] objectWithData:data];
		NSArray *results = [info objectForKey:@"results"];
		
		if (results.count == 0) {
			DLog(@"nothing good from google for address [%@]", address);
			return;
		}
		
		NSDictionary *result = [results objectAtIndex:0];
		NSDictionary *geometry = [result objectForKey:@"geometry"];
		NSDictionary *location = [geometry objectForKey:@"location"];
		
		latitude = [[location objectForKey:@"lat"] doubleValue];
		longitude = [[location objectForKey:@"lng"] doubleValue];
	}
	
	// cache the results
	{
		[_cacheDb setString:city forKey:[ipaddr stringByAppendingString:@"__city"]];
		[_cacheDb setString:state forKey:[ipaddr stringByAppendingString:@"__state"]];
		[_cacheDb setString:country forKey:[ipaddr stringByAppendingString:@"__country"]];
		[_cacheDb setString:code forKey:[ipaddr stringByAppendingString:@"__code"]];
		[_cacheDb setString:[[NSNumber numberWithDouble:latitude] stringValue] forKey:[ipaddr stringByAppendingString:@"__latitude"]];
		[_cacheDb setString:[[NSNumber numberWithDouble:longitude] stringValue] forKey:[ipaddr stringByAppendingString:@"__longitude"]];
		
		//DLog(@"cached %f, %f for %@", latitude, longitude, ipaddr);
	}
	
	handler(latitude, longitude, city, state, country, code);
}

@end
