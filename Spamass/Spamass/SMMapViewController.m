//
//  SMMapViewController.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.08.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "SMMapViewController.h"

@interface SMMapMarker : NSObject
{
@public
	NSString *mKey;
	NSString *mLabel;
	double mLatitude;
	double mLongitude;
	NSImageView *mView;
}
@end

@implementation SMMapMarker
@end





@interface SMMapViewController ()
{
	NSUInteger mGridWidth;
	NSUInteger mGridHeight;
	NSUInteger mImageWidth;
	NSUInteger mImageHeight;
	
	NSImage *mMarkerImg;
	NSMutableDictionary *mMarkers;
	
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
			// ...
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
	mMarkers = [[NSMutableDictionary alloc] init];
	
	NSData *crosshairData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"world/crosshair" ofType:@".png"]];
	mMarkerImg = [[NSImage alloc] initWithData:crosshairData];
	
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
- (void)unsetMarkerForKey:(NSString *)key
{
	if (key.length == 0)
		return;
	
	SMMapMarker *marker = [mMarkers objectForKey:key];
	
	if (marker) {
		[marker->mView removeFromSuperview];
		[mMarkers removeObjectForKey:key];
		[self.view setNeedsDisplay:TRUE];
	}
}

/**
 *
 *
 */
- (void)setMarkerAtLatitude:(double)latitude longitude:(double)longitude withLabel:(NSString *)label forKey:(NSString *)key
{
	NSSize windowSize = self.view.window.frame.size;
	NSUInteger imageSize = MIN(windowSize.width / mGridWidth, windowSize.height / mGridHeight);
	double mapWidth = (double)mGridWidth * (double)imageSize;
//double mapHeight = 16. * (double)imageSize;
	SMMapMarker *marker = [mMarkers objectForKey:key];
	
	NSUInteger longitudeX = (NSUInteger)((int)mapWidth * (180 + longitude) / 360) % (int)mapWidth;
	
	/*
	// convert from degrees to radians
	double radians = latitude * M_PI / 180.;
	DLog(@"radians = %f", radians);
	
	// mercator projection with equator of two pi units
	double newlat = log(tan(radians/2.) + (M_PI/4.));
	DLog(@"newlat [1] = %f", newlat);
	
	// adjust to our map size
	newlat = (mapHeight / 2.) - (mapWidth * newlat / (2. * M_PI));
	DLog(@"newlat [2] = %f", newlat);
	
	// removed two rows of images from the top of the map
	newlat -= (double)(imageSize * 2);
	DLog(@"newlat [3] = %f", newlat);
	
	// project from the bottom of the window
	newlat = windowSize.height - newlat;
	DLog(@"newlat [4] = %f", newlat);
	*/
	
	// convert from degrees to radians
	double radians = latitude * M_PI / 180.;
	
	// mercator projection with equator of two pi units
	double newlat = log(tan((radians / 2.) + (M_PI / 4.)));
	
	// adjust to our map size
	newlat = (4096. / 2.) - (4096. * newlat / (2. * M_PI));
	
	// removed two rows of images from the top of the map
	newlat -= (double)(256. * 2.);
	
	// adjust to scale
	newlat *= (double)imageSize / 256.;
	
	// project from the bottom of the window
	newlat = windowSize.height - newlat;
	
	if (!marker) {
		[mMarkers setObject:(marker = [[SMMapMarker alloc] init]) forKey:key];
		marker->mView = [[NSImageView alloc] initWithFrame:NSMakeRect(longitudeX, newlat, 10, 10)];
		marker->mView.image = mMarkerImg;
		marker->mKey = key;
	}
	
//NSUInteger latitudeY = mapWidth - latitude;
//NSImageView *crosshairView = [[NSImageView alloc] initWithFrame:NSMakeRect(longitudeX, latitudeY, 10, 10)];
	
	marker->mView.frame = NSMakeRect(longitudeX, newlat, 10, 10);
	marker->mLatitude = latitude;
	marker->mLongitude = longitude;
	marker->mLabel = label;
	
	[self.view addSubview:marker->mView];
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
