//
//  Regionizer.m
//  SuffrageDaemon
//
//  Created by Curtis Jones on 2011.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Regionizer.h"
#import <arpa/inet.h>
#import <stdint.h>
#import "swap.h"

@interface Regionizer (PrivateMethods)
- (void)loadCountryCodes;
- (void)loadIPAddressAllocations;
- (void)loadIPAddressAllocationFile:(NSString *)filePath;
- (void)parseIPAddressAllocationFile:(NSString *)filePath allocations:(NSMutableArray *)allocs;
@end

@implementation Regionizer

int
__qsort_compare (const void *arg1, const void *arg2)
{
	struct riralloc *alloc1 = (struct riralloc *)arg1;
	struct riralloc *alloc2 = (struct riralloc *)arg2;
	
	if (alloc1->addrbeg < alloc2->addrbeg)
		return -1;
	else if (alloc1->addrbeg > alloc2->addrbeg)
		return 1;
	else
		return 0;
}

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		[self loadIPAddressAllocations];
	}
	
	return self;
}

/**
 *
 *
 */
- (void)dealloc
{
	free(mAllocs);
	mAllocs = NULL;
	
	[super dealloc];
}

/**
 *
 *
 */
/*
- (void)loadCountryCodes
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Country Codes" ofType:@"txt"];
	NSString *fileData = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *lines = [fileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in lines) {
		NSArray *parts = [line componentsSeparatedByString:@"\t"];
		
		NSString *code = [parts objectAtIndex:0];
		NSString *name = [parts objectAtIndex:1];
		
		// TODO: do something
	}
	
	[fileData release];
	[pool release];
}
*/

/**
 *
 *
 */
- (void)loadIPAddressAllocations
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	NSString *basePath = [appPath stringByAppendingPathComponent:@"Contents/Resources"];
	NSMutableArray *allocs = [NSMutableArray array];
	
	[self parseIPAddressAllocationFile:[basePath stringByAppendingPathComponent:@"delegated-afrinic-latest"] allocations:allocs];
	[self parseIPAddressAllocationFile:[basePath stringByAppendingPathComponent:@"delegated-apnic-latest"] allocations:allocs];
	[self parseIPAddressAllocationFile:[basePath stringByAppendingPathComponent:@"delegated-arin-latest"] allocations:allocs];
	[self parseIPAddressAllocationFile:[basePath stringByAppendingPathComponent:@"delegated-lacnic-latest"] allocations:allocs];
	[self parseIPAddressAllocationFile:[basePath stringByAppendingPathComponent:@"delegated-ripencc-latest"] allocations:allocs];
	
	if (NULL == (mAllocs = (struct riralloc *)malloc(sizeof(struct riralloc) * [allocs count]))) {
		NSLog(@"%s.. failed to malloc(), %s", __PRETTY_FUNCTION__, strerror(errno));
		return;
	}
	
	memset(mAllocs, 0, sizeof(struct riralloc) * [allocs count]);
	
	for (NSString *line in allocs) {
		NSArray *parts = [line componentsSeparatedByString:@"|"];
		
		if ([parts count] != 7)
			continue;
		
//	NSString *rir = [parts objectAtIndex:0];     // rir name
		NSString *cc = [parts objectAtIndex:1];      // country code
		NSString *type = [parts objectAtIndex:2];    // ipv4 | ipv6
		NSString *addr = [parts objectAtIndex:3];    // ip address
		NSString *size = [parts objectAtIndex:4];    // number of addresses in allocation
//	NSString *date = [parts objectAtIndex:5];    // allocation date
//	NSString *state = [parts objectAtIndex:6];   // assigned | allocated
		
		if (FALSE == [type isEqualToString:@"ipv4"])
			continue;
		
		uint32_t addrbeg, addrend;
		const char *ccstr = [cc cStringUsingEncoding:NSUTF8StringEncoding];
		
		addrbeg = swap32(inet_addr([addr cStringUsingEncoding:NSUTF8StringEncoding]));
		addrend = addrbeg + (uint32_t)[size integerValue];
		
		mAllocs[mAllocCnt].addrbeg = addrbeg;
		mAllocs[mAllocCnt].addrend = addrend;
		mAllocs[mAllocCnt].cc[0] = ccstr[0];
		mAllocs[mAllocCnt].cc[1] = ccstr[1];
		
		mAllocCnt += 1;
	}
	
	qsort(mAllocs, mAllocCnt, sizeof(struct riralloc), __qsort_compare);

	[pool release];
}

/**
 *
 *
 */
- (void)parseIPAddressAllocationFile:(NSString *)filePath allocations:(NSMutableArray *)allocs
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *fileData = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *lines = [fileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in lines) {
		NSArray *parts = [line componentsSeparatedByString:@"|"];
		
		if ([parts count] != 7)
			continue;
		
		NSString *type = [parts objectAtIndex:2];
		
		if (FALSE == [type isEqualToString:@"ipv4"])
			continue;
		
		[allocs addObject:line];
	}
	
	[fileData release];
	[pool release];
}

/**
 * The address is expected in host byte order; not network byte order.
 *
 */
- (uint16_t)regionForIPv4Address:(uint32_t)address
{
	int upper, lower, middle;
	struct riralloc *tmpalloc;
	
	if (0x7F == (address >> 24) || 0x0A == (address >> 24))
		return ('P'<<8) | 'N';
	
	lower = 0;
	upper = mAllocCnt - 1;
	
	if (address < mAllocs[0].addrbeg)
		return 0;
	else if (address > mAllocs[mAllocCnt-1].addrend)
		return 0;
	
	while (1) {
		if (lower == upper) {
			tmpalloc = &mAllocs[lower];
			
			if (tmpalloc->addrbeg <= address && tmpalloc->addrend >= address)
				return (tmpalloc->cc[0] << 8) | tmpalloc->cc[1];
			else
				return 0;
		}
		
		middle = lower + ((upper - lower) / 2);
		tmpalloc = &mAllocs[middle];
		
		if (tmpalloc->addrbeg > address)
			upper = middle - 1;
		else if (tmpalloc->addrend < address) {
			lower = middle + 1;
		}
		else
			return (tmpalloc->cc[0] << 8) | tmpalloc->cc[1];
	}
	
	return 0;
}

@end
