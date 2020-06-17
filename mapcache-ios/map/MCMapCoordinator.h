//
//  MCMapCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCGeoPackageListCoordinator.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageManager.h"
#import "MCSettingsCoordinator.h"
#import "MCBoundingBoxGuideView.h"
#import "MCDrawingStatusViewController.h"
#import "MCGeoPackageRepository.h"
#import "MCCreateGeoPacakgeViewController.h"
#import "MCFeatureLayerDetailsViewController.h"
#import "MCMapPointDataViewController.h"



@class MCMapViewController;
@protocol MCMapActionDelegate;

@protocol MCMapDelegate <NSObject>
- (void) updateMapLayers;
- (void) toggleGeoPackage:(MCDatabase *) geoPackage;
- (void) zoomToSelectedGeoPackage:(NSString *) geoPackageName;
- (void) setupTileBoundingBoxGuide:(UIView *) boudingBoxGuideView;
- (void) removeTileBoundingBoxGuide;
- (CLLocationCoordinate2D) convertPointToCoordinate:(CGPoint) point;
@end


@interface MCMapCoordinator : NSObject <MCMapDelegate, MCMapActionDelegate, MCDrawingStatusDelegate, MCCreateGeoPackageDelegate, MCFeatureLayerCreationDelegate, MCMapPointDataDelegate>
- (instancetype) initWithMapViewController:(MCMapViewController *) mapViewController;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@end
