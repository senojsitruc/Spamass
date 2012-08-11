//
//  SMMapViewController.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.08.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMMapViewController.h"

@interface SMMapViewController ()
{
	NSUInteger mGridWidth;
	NSUInteger mGridHeight;
	NSUInteger mImageWidth;
	NSUInteger mImageHeight;
	
	NSMutableArray *mImageViews;
}

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
	mGridWidth = 16, mGridHeight = 10;
	mImageWidth = mImageHeight = 256;
	mImageViews = [[NSMutableArray alloc] init];
	
	NSView *worldView = [[NSView alloc] initWithFrame:NSMakeRect(0., 0., (mGridWidth*mImageWidth), (mGridHeight*mImageHeight))];
	NSString *world = [[NSBundle mainBundle] pathForResource:@"world" ofType:@""];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:world error:nil];
	
	// filter out the non world view image files then sort the files by their grid location - top
	// left through bottom right.
	{
		NSMutableArray *filtered = [[NSMutableArray alloc] init];
		
		[files enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSString *file = (NSString *)obj;
			NSString *name = [file stringByDeletingPathExtension];
			NSArray *parts = [name componentsSeparatedByString:@"-"];
			
			if (parts.count == 3)
				[filtered addObject:file];
		}];
		
		files = [filtered sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
			NSString *name1 = [(NSString *)obj1 stringByDeletingPathExtension];
			NSString *name2 = [(NSString *)obj2 stringByDeletingPathExtension];
			
			NSArray *parts1 = [name1 componentsSeparatedByString:@"-"];
			NSArray *parts2 = [name2 componentsSeparatedByString:@"-"];
			
			NSUInteger imageY1 = [[parts1 objectAtIndex:1] integerValue];
			NSUInteger imageX1 = [[parts1 objectAtIndex:2] integerValue];
			
			NSUInteger imageY2 = [[parts2 objectAtIndex:1] integerValue];
			NSUInteger imageX2 = [[parts2 objectAtIndex:2] integerValue];
			
			if (imageY1 > imageY2)
				return NSOrderedDescending;
			else if (imageY1 < imageY2)
				return NSOrderedAscending;
			else if (imageX1 > imageX2)
				return NSOrderedDescending;
			else if (imageX1 < imageX2)
				return NSOrderedAscending;
			else
				return NSOrderedSame;
		}];
	}
	
	[files enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSString *file = (NSString *)obj;
		NSData *data = [NSData dataWithContentsOfFile:[world stringByAppendingPathComponent:file]];
		NSUInteger imageX = ndx % mGridWidth;
		NSUInteger imageY = ndx / mGridWidth;
		NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect((imageX*mImageWidth), ((mGridHeight-imageY-1)*mImageHeight), mImageWidth, mImageHeight)];
		NSImage *image = [[NSImage alloc] initWithData:data];
		image.size = NSMakeSize(mImageWidth, mImageHeight);
		imageView.image = image;
		[worldView addSubview:imageView];
		[mImageViews addObject:imageView];
	}];
	
	self.view = worldView;
}

/**
 *
 *
 */
- (void)setMarkerAtLongitude:(double)longitude latitude:(double)latitude
{
	NSSize windowSize = self.view.window.frame.size;
	NSUInteger mapWidth = MIN(windowSize.width, windowSize.height);
	NSUInteger mapHeight = MIN(windowSize.width, windowSize.height);
	NSUInteger longitudeX = (NSUInteger)(mapWidth * (180 + longitude) / 360.) % mapWidth + 0;
	
	latitude = latitude * M_PI / 180.; // degrees to radians
	latitude = log(tan(latitude/2.) + (M_PI/4.));
	latitude = (mapHeight / 2.) - (mapWidth * latitude / (2. * M_PI));
	
	
	
	NSUInteger latitudeY = mapWidth - latitude;
	
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





#pragma mark - NSWindowDelegate

- (void)sizeToFit
{
	NSSize windowSize = self.view.window.frame.size;
	NSUInteger imageWidth, imageHeight;
	
	imageWidth = imageHeight = MIN(windowSize.width / mGridWidth, windowSize.height / mGridHeight);
	
	[mImageViews enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSImageView *imageView = (NSImageView *)obj;
		NSUInteger imageX = ndx % mGridWidth;
		NSUInteger imageY = ndx / mGridWidth;
		imageView.frame = NSMakeRect((imageX*imageWidth), ((mGridHeight-imageY-1)*imageHeight), imageWidth, imageHeight);
	}];
	
	[self.view setNeedsDisplay:TRUE];
}

@end

































