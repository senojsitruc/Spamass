//
//  SMMapViewController.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.08.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMMapViewController.h"

@interface SMMapViewController ()

@end

@implementation SMMapViewController

/**
 *
 *
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

/**
 *
 *
 */
- (void)loadView
{
	NSUInteger gridWidth=16, gridHeight=16;
	NSUInteger imageWidth=75, imageHeight=75;
	NSView *worldView = [[NSView alloc] initWithFrame:NSMakeRect(0., 0., (gridWidth*imageWidth), (gridHeight*imageHeight))];
	NSString *world = [[NSBundle mainBundle] pathForResource:@"world" ofType:@""];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:world error:nil];
	
	for (NSString *file in files) {
		NSString *name = [file stringByDeletingPathExtension];
		NSArray *parts = [name componentsSeparatedByString:@"-"];
		
		if ([parts count] != 3) {
			NSLog(@"%s.. invalid file name [%@]", __PRETTY_FUNCTION__, file);
			continue;
		}
		
		NSUInteger imageY = [[parts objectAtIndex:1] integerValue];
		NSUInteger imageX = [[parts objectAtIndex:2] integerValue];
		NSData *data = [NSData dataWithContentsOfFile:[world stringByAppendingPathComponent:file]];
		NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect((imageX*imageWidth), ((gridHeight-imageY-1)*imageHeight), imageWidth, imageHeight)];
		NSImage *image = [[NSImage alloc] initWithData:data];
		image.size = NSMakeSize(imageWidth, imageHeight);
		imageView.image = image;
		[worldView addSubview:imageView];
	}
	
	worldView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
	worldView.autoresizesSubviews = TRUE;
	self.view = worldView;
}

/**
 *
 *
 */
- (void)setMarkerAtLongitude:(double)longitude latitude:(double)latitude
{
	NSUInteger longitudeX = (NSUInteger)(1200 * (180 + longitude) / 360.) % 1200 + 0;
	
	latitude = latitude * M_PI / 180.; // degrees to radians
	latitude = log(tan(latitude/2.) + (M_PI/4.));
	latitude = (1200. / 2.) - (1200. * latitude / (2. * M_PI));
	
	
	
	NSUInteger latitudeY = 1200. - latitude;
	
	NSLog(@"%s.. longitudeX=%lu, latitudeY=%lu", __PRETTY_FUNCTION__, longitudeX, latitudeY);
	
	NSData *crosshairData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"world/crosshair" ofType:@".png"]];
	NSImage *crosshair = [[NSImage alloc] initWithData:crosshairData];
	NSImageView *crosshairView = [[NSImageView alloc] initWithFrame:NSMakeRect(longitudeX, latitudeY, 10, 10)];
	crosshairView.image = crosshair;
	
	[self.view addSubview:crosshairView];
	
	
	/*
	$worldMapWidth = (($mapWidth / $mapLonDelta) * 360) / (2 * M_PI);
	$mapOffsetY = ($worldMapWidth / 2 * log((1 + sin($mapLatBottomDegree)) / (1 - sin($mapLatBottomDegree))));
	$y = $mapHeight - (($worldMapWidth / 2 * log((1 + sin($lat)) / (1 - sin($lat)))) - $mapOffsetY);
	
	return array($x, $y)
	*/
	
	
	
	
	/*
	lat = lat * Math.PI / 180;  // convert from degrees to radians
	y = Math.log(Math.tan((lat/2) + (Math.PI/4)));  // do the Mercator projection (w/ equator of 2pi units)
	y = (map_height / 2) - (map_width * y / (2 * Math.PI)) + y_pos;   // fit it to our map
	
	x -= x_pos;
	y -= y_pos;
	
	draw_point(x - half_dot, y - half_dot);
	
	
	
	var dot_size = 3;
	var longitude_shift = 55;   // number of pixels your map's prime meridian is off-center.
	var x_pos = 54;
	var y_pos = 19;
	var map_width = 430;
	var map_height = 332;
	var half_dot = Math.floor(dot_size / 2);
	
    // latitude: using the Mercator projection
	}
	*/
	
}

@end
