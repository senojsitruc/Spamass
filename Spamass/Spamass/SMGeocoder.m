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

@interface SMGeocoder ()
{
	APLevelDB *mDb;
	dispatch_queue_t mQueue;
}
@end

@implementation SMGeocoder

/**
 *
 *
 */
- (id)initWithDb:(APLevelDB *)db
{
	self = [super init];
	
	if (self) {
		mDb = db;
		mQueue = dispatch_queue_create("net.spamass.geocoder", DISPATCH_QUEUE_CONCURRENT);
	}
	
	return self;
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
	
	handler = [handler copy];
	
	dispatch_async(mQueue, ^{
		[self __geocode:ipaddr handler:handler];
	});
}

/**
 * First check our database. Then call hostip.info. Then call google. And don't forget to add a 
 * cache entry.
 */
- (void)__geocode:(NSString *)ipaddr handler:(SMGeocoderHandler)handler
{
	__block NSString *city=nil, *state=nil, *country=nil, *code=nil;
	double latitude=0., longitude=0.;
	
	// grab cached values from the database
	{
		NSString *lat=nil, *lon=nil;
		
		city = [mDb stringForKey:[ipaddr stringByAppendingString:@"__city"]];
		state = [mDb stringForKey:[ipaddr stringByAppendingString:@"__state"]];
		country = [mDb stringForKey:[ipaddr stringByAppendingString:@"__country"]];
		code = [mDb stringForKey:[ipaddr stringByAppendingString:@"__code"]];
		lat = [mDb stringForKey:[ipaddr stringByAppendingString:@"__latitude"]];
		lon = [mDb stringForKey:[ipaddr stringByAppendingString:@"__longitude"]];
		
		//NSLog(@"%s.. got from cache!", __PRETTY_FUNCTION__);
		
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
			NSLog(@"%s.. no data for url [%@]", __PRETTY_FUNCTION__, url);
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
				NSLog(@"%s.. invalid line [%@]", __PRETTY_FUNCTION__, line);
				return;
			}
			
			NSString *label = [parts objectAtIndex:0];
			NSString *value = [parts objectAtIndex:1];
			
			if ([label isEqualToString:@"Country"])
				country = value;
			else if ([label isEqualToString:@"City"])
				city = value;
		}];
		
		if (country.length == 0) {
			NSLog(@"%s.. unable to geocode [%@]", __PRETTY_FUNCTION__, ipaddr);
			return;
		}
		
		if ([city isEqualToString:@"(Unknown city)"])
			city = nil;
		
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
			
			NSLog(@"%s.. asking google for location [%@]", __PRETTY_FUNCTION__, address);
		}
		
		NSURL *url = [NSURL URLWithString:[@"https://maps.googleapis.com/maps/api/geocode/json?sensor=true&address=" stringByAppendingString:[address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		NSURLRequest *requ = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
		NSData *data = [NSURLConnection sendSynchronousRequest:requ returningResponse:nil error:&error];
		
		if (!data) {
			NSLog(@"%s.. no data for url [%@]", __PRETTY_FUNCTION__, url);
			return;
		}
		
		NSDictionary *info = [[[SBJsonParser alloc] init] objectWithData:data];
		NSArray *results = [info objectForKey:@"results"];
		
		if (results.count == 0) {
			NSLog(@"%s.. nothing good from google for address [%@]", __PRETTY_FUNCTION__, address);
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
		[mDb setString:city forKey:[ipaddr stringByAppendingString:@"__city"]];
		[mDb setString:state forKey:[ipaddr stringByAppendingString:@"__state"]];
		[mDb setString:country forKey:[ipaddr stringByAppendingString:@"__country"]];
		[mDb setString:code forKey:[ipaddr stringByAppendingString:@"__code"]];
		[mDb setString:[[NSNumber numberWithDouble:latitude] stringValue] forKey:[ipaddr stringByAppendingString:@"__latitude"]];
		[mDb setString:[[NSNumber numberWithDouble:longitude] stringValue] forKey:[ipaddr stringByAppendingString:@"__longitude"]];
	}
	
	handler(latitude, longitude, city, state, country, code);
}

@end
