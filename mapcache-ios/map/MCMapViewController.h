//
//  MCMapViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "NGADrawerCoordinator.h"
#import "GPKGSDatabases.h"
#import "GPKGSDatabase.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSUtils.h"
#import "GPKGUtils.h"
#import "GPKGMapUtils.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGTileTableScaling.h"
#import "GPKGMultipleFeatureIndexResults.h"
#import "GPKGFeatureShapes.h"
#import "SFPProjectionFactory.h"
#import "SFGeometryEnvelopeBuilder.h"


@interface MCMapViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
-(int) updateInBackgroundWithZoom: (BOOL) zoom;
@end
