//
//  SMGeocoder.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.11.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SMGeocoderHandler)(double, double, NSString*, NSString*, NSString*, NSString*);

@class APLevelDB;

@interface SMGeocoder : NSObject

/**
 *
 */
- (id)initWithCacheDb:(APLevelDB *)cacheDb regionDb:(APLevelDB *)regionDb;

/**
 *
 */
- (void)geocode:(NSString *)ipaddr handler:(SMGeocoderHandler)handler;
- (NSString *)countryCodeForIPAddress:(NSString *)ipaddr;
- (NSString *)countryNameForIPAddress:(NSString *)ipaddr;

@end
