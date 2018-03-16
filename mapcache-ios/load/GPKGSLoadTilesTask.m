//
//  GPKGSLoadTilesTask.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/24/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSLoadTilesTask.h"
#import "GPKGTileGenerator.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGUrlTileGenerator.h"
#import "GPKGFeatureTileGenerator.h"
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGProjectionFactory.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"

@interface GPKGSLoadTilesTask ()

@property (nonatomic, strong) NSNumber *maxTiles;
@property (nonatomic) int progress;
@property (nonatomic, strong) GPKGTileGenerator *tileGenerator;
@property (nonatomic, strong) NSObject<GPKGSLoadTilesProtocol> *callback;
@property (nonatomic) BOOL canceled;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation GPKGSLoadTilesTask

+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                  andDatabase: (NSString *) database
                     andTable: (NSString *) tableName
                       andUrl: (NSString *) tileUrl
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
            andStandardFormat: (BOOL) standardWebMercatorFormat
               andBoundingBox: (GPKGBoundingBox *) boundingBox
               andTileScaling: (GPKGTileScaling *) scaling
                 andAuthority: (NSString *) authority
                      andCode: (NSString *) code
                     andLabel: (NSString *) label{
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [manager open:database];
    }
    @finally {
        [manager close];
    }
    
    GPKGProjection * projection = [GPKGProjectionFactory projectionWithAuthority:authority andCode:code];
    GPKGBoundingBox * bbox = [self transformBoundingBox:boundingBox withProjection:projection];
    
    GPKGTileGenerator * tileGenerator = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:geoPackage andTableName:tableName andTileUrl:tileUrl andMinZoom:minZoom andMaxZoom:maxZoom andBoundingBox:bbox andProjection:projection];
    [self setTileGenerator:tileGenerator withMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:compressFormat andCompressQuality:compressQuality andCompressScale:compressScale andStandardFormat:standardWebMercatorFormat andBoundingBox:boundingBox andTileScaling:scaling];
    
    [self loadTilesWithCallback:callback andGeoPackage:geoPackage andTable:tableName andTileGenerator:tileGenerator andLabel:label];
}

+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                andGeoPackage: (GPKGGeoPackage *) geoPackage
                     andTable: (NSString *) tableName
              andFeatureTiles: (GPKGFeatureTiles *) featureTiles
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
            andStandardFormat: (BOOL) standardWebMercatorFormat
               andBoundingBox: (GPKGBoundingBox *) boundingBox
               andTileScaling: (GPKGTileScaling *) scaling
                 andAuthority: (NSString *) authority
                      andCode: (NSString *) code
                     andLabel: (NSString *) label{
    
    GPKGProjection * projection = [GPKGProjectionFactory projectionWithAuthority:authority andCode:code];
    GPKGBoundingBox * bbox = [self transformBoundingBox:boundingBox withProjection:projection];
    
    GPKGTileGenerator * tileGenerator = [[GPKGFeatureTileGenerator alloc] initWithGeoPackage:geoPackage andTableName:tableName andFeatureTiles:featureTiles andMinZoom:minZoom andMaxZoom:maxZoom andBoundingBox:bbox andProjection:projection];
    [self setTileGenerator:tileGenerator withMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:compressFormat andCompressQuality:compressQuality andCompressScale:compressScale andStandardFormat:standardWebMercatorFormat andBoundingBox:boundingBox andTileScaling:scaling];
    
    [self loadTilesWithCallback:callback andGeoPackage:geoPackage andTable:tableName andTileGenerator:tileGenerator andLabel:label];
}

+(GPKGBoundingBox *) transformBoundingBox: (GPKGBoundingBox *) boundingBox withProjection: (GPKGProjection *) projection{
    
    GPKGBoundingBox * transformedBox = boundingBox;
    
    if(![projection isEqualToAuthority:PROJ_AUTHORITY_EPSG andNumberCode:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]]){
        GPKGBoundingBox * bounded = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
        GPKGProjectionTransform * transform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM andToProjection:projection];
        transformedBox = [transform transformWithBoundingBox:bounded];
    }
    
    return transformedBox;
}

+(void) setTileGenerator: (GPKGTileGenerator *) tileGenerator
             withMinZoom: (int) minZoom
              andMaxZoom: (int) maxZoom
       andCompressFormat: (enum GPKGCompressFormat) compressFormat
      andCompressQuality: (int) compressQuality
        andCompressScale: (int) compressScale
       andStandardFormat: (BOOL) standardWebMercatorFormat
          andBoundingBox: (GPKGBoundingBox *) boundingBox
          andTileScaling: (GPKGTileScaling *) scaling{
    
    if(minZoom > maxZoom){
        [NSException raise:@"Zoom Range" format:@"Min zoom of %d can not be larger than max zoom of %d", minZoom, maxZoom];
    }
    
    [tileGenerator setCompressFormat:compressFormat];
    [tileGenerator setCompressQualityAsIntPercentage:compressQuality];
    [tileGenerator setCompressScaleAsIntPercentage:compressScale];
    [tileGenerator setStandardWebMercatorFormat:standardWebMercatorFormat];
    [tileGenerator setScaling:scaling];
}

+(void) loadTilesWithCallback:(NSObject<GPKGSLoadTilesProtocol> *)callback andGeoPackage:(GPKGGeoPackage *)geoPackage andTable:(NSString *)tableName andTileGenerator: (GPKGTileGenerator *) tileGenerator andLabel: (NSString *) label{
    
    GPKGSLoadTilesTask * loadTilesTask = [[GPKGSLoadTilesTask alloc] initWithCallback:callback];
    
    [tileGenerator setProgress:loadTilesTask];
    
    [loadTilesTask setTileGenerator:tileGenerator];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"%@ %@ - %@", label, geoPackage.name, tableName]
                              message:@""
                              delegate:loadTilesTask
                              cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_STOP_LABEL]
                              otherButtonTitles:nil];
    UIProgressView *progressView = [GPKGSUtils buildProgressBarView];
    [alertView setValue:progressView forKey:@"accessoryView"];
    
    loadTilesTask.alertView = alertView;
    loadTilesTask.progressView = progressView;
    
    [alertView show];
    
    [loadTilesTask execute];
    
}

-(instancetype) initWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback{
    self = [super init];
    if(self != nil){
        self.callback = callback;
        self.progress = 0;
        self.canceled = false;
    }
    return self;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0){
        self.canceled = true;
    }
}

-(void) execute{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        
        int count = 0;
        
        @try {
            count = [self.tileGenerator generateTiles];
            if(count < [self.maxTiles intValue] && [self.tileGenerator class] != [GPKGFeatureTileGenerator class]){
                NSString * countError = [NSString stringWithFormat:@"Fewer tiles were generated than expected. Expected: %@, Actual: %u", self.maxTiles, count];
                if(self.error != nil){
                    countError = [NSString stringWithFormat:@"%@, Error: %@", countError, self.error];
                }
                self.error = countError;
            }
        }
        @catch (NSException *e) {
            self.error = [e description];
        }
        @finally{
            [self.tileGenerator close];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.alertView dismissWithClickedButtonIndex:-1 animated:true];
            
            if(self.error == nil){
                [self.callback onLoadTilesCompleted:count];
            }else{
                if(self.canceled){
                    [self.callback onLoadTilesCanceled:[self.error description] withCount:count];
                }else{
                    [self.callback onLoadTilesFailure:[self.error description] withCount:count];
                }
            }
        });
        
    });
    
}

-(void) setMax: (int) max{
    self.maxTiles = [NSNumber numberWithInt:max];
    [self addProgress:0];
}

-(void) addProgress: (int) progress{
    self.progress += progress;
    float progressPercentage = self.progress / [self.maxTiles floatValue];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.alertView setMessage:[NSString stringWithFormat:@"( %d of %@ )", self.progress, self.maxTiles]];
        [self.progressView setProgress:progressPercentage];
    });
}

-(BOOL) isActive{
    return !self.canceled;
}

-(BOOL) cleanupOnCancel{
    return false;
}

-(void) completed{
    
}

-(void) failureWithError: (NSString *) error{
    self.error = error;
}

+(GPKGTileScaling *) tileScaling{
    // TODO Set these values from tile creation and updates
    return [[GPKGTileScaling alloc] initWithScalingType:GPKG_TSC_CLOSEST_IN_OUT andZoomIn:[NSNumber numberWithInt:2] andZoomOut:[NSNumber numberWithInt:2]];
}

@end
