//
//  SMMapViewController.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.08.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMMapViewController : NSViewController

- (void)setMarkerAtLatitude:(double)latitude longitude:(double)longitude withLabel:(NSString *)label forKey:(NSString *)key;
- (void)unsetMarkerForKey:(NSString *)key;

- (void)sizeToFit;

@end
