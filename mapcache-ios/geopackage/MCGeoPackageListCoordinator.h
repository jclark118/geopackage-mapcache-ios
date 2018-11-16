//
//  MCGeoPackageListCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "GPKGSDatabase.h"
#import "MCGeoPackageCoordinator.h"
#import "MCGeoPackageList.h"
#import "GPKGSFeatureOverlayTable.h"
#import "MCGeopackageSingleViewController.h"
#import "MCGeoPackageCoordinator.h"
#import "GPKGSDatabases.h"
#import "MCDownloadCoordinator.h"

@protocol MCMapDelegate <NSObject>
- (void) updateMapLayers;
- (void) toggleGeoPackage:(GPKGSDatabase *) geoPackage;
- (void) zoomToSelectedGeoPackage:(NSString *) geoPackageName;
@end


@interface MCGeoPackageListCoordinator : NSObject <MCGeoPackageCoordinatorDelegate, MCGeoPacakageListViewDelegate, GPKGSDownloadCoordinatorDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) id<MCMapDelegate> mcMapDelegate;
- (void)start;
@end
