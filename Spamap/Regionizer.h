//
//  Regionizer.h
//  SuffrageDaemon
//
//  Created by Curtis Jones on 2011.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

struct riralloc
{
	uint32_t addrbeg;
	uint32_t addrend;
	unsigned char cc[3];
};

@interface Regionizer : NSObject
{
	struct riralloc *mAllocs;
	int mAllocCnt;
}

- (uint16_t)regionForIPv4Address:(uint32_t)address;

@end
