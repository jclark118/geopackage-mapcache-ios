//
//  MCTileHelper.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/20/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileHelper.h"


@interface MCTileHelper()
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic, strong) MCDatabases *active;
@end


@implementation MCTileHelper

- (instancetype) init {
    self = [super init];
    self.active = [MCDatabases getInstance];
    self.manager = [GPKGGeoPackageFactory manager];
    
    return self;
}


- (instancetype) initWithTileHelperDelegate: (id<MCTileHelperDelegate>) delegate {
    self = [super init];
    self.tileHelperDelegate = delegate;
    self.active = [MCDatabases getInstance];
    self.manager = [GPKGGeoPackageFactory manager];
    
    return self;
}


- (void) prepareTiles {
    NSArray *activeDatabases = [[NSArray alloc] initWithArray: [self.active getDatabases]];

    for (MCDatabase *database in activeDatabases) {
        GPKGGeoPackage *geoPackage;
        
        @try {
            geoPackage = [self.manager open:database.name];
            
            if (geoPackage != nil) {
                for (MCTileTable *tiles in [database getTiles]) {
                    MKTileOverlay *tileOverlay = [self createOverlayForTiles:tiles fromGeoPacakge:geoPackage];
                    if (tileOverlay != nil) {
                        [self.tileHelperDelegate addTileOverlayToMapView:tileOverlay withTable:tiles];
                    }
                }
            }
        } @catch (NSException *e) {
            NSLog(@"MCTileHelper - prepareTiles: %@", e.reason);
        }
    }
}


- (void) prepareTilesForGeoPackage: (GPKGGeoPackage *) geoPackage andDatabase:(MCDatabase *) database {
    for (MCTileTable *tiles in [database getTiles]) {
        @try {
            MKTileOverlay *tileOverlay = [self createOverlayForTiles:tiles fromGeoPacakge:geoPackage];
            [self.tileHelperDelegate addTileOverlayToMapView:tileOverlay withTable:tiles];
        } @catch (NSException *e) {
            NSLog(@"MCTileHelper - prepareTilesForGeoPackage: %@", [e description]);
        }
    }
}


// MCTileHelper version of -(void) displayTiles: (GPKGSTileTable *)
-(MKTileOverlay *) createOverlayForTiles: (MCTileTable *) tiles fromGeoPacakge:(GPKGGeoPackage *) geoPackage {
    GPKGBoundedOverlay *overlay = nil;
    
    @try {
        GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName:tiles.name];
        GPKGTileTableScaling *tileTableScaling = [[GPKGTileTableScaling alloc] initWithGeoPackage:geoPackage andTileDao:tileDao];
        GPKGTileScaling *tileScaling = [tileTableScaling tileScaling];
        overlay = [GPKGOverlayFactory boundedOverlay:tileDao andScaling:tileScaling];
        overlay.canReplaceMapContent = false;
        
        GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
        
        // TODO: handle feature tiles.
        //    GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
        //    NSArray<GPKGFeatureDao *> * featureDaos = [linker getFeatureDaosForTileTable:tileDao.tableName];
        //    for(GPKGFeatureDao * featureDao in featureDaos){
        //
        //        // Create the feature tiles
        //        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        //
        //        self.featureOverlayTiles = true;
        //
        //        // Add the feature overlay query
        //        GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:overlay andFeatureTiles:featureTiles];
        //        [featureOverlayQuery calculateStylePixelBounds];
        //        [self.featureOverlayQueries addObject:featureOverlayQuery];
        //    }
        
        GPKGBoundingBox *displayBoundingBox = [tileMatrixSet boundingBox];
        GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage tileMatrixSetDao];
        GPKGSpatialReferenceSystem *tileMatrixSetSrs = [tileMatrixSetDao srs:tileMatrixSet];
        GPKGContents *contents = [tileMatrixSetDao contents:tileMatrixSet];
        GPKGBoundingBox *contentsBoundingBox = [contents boundingBox];
        if(contentsBoundingBox != nil){
            GPKGContentsDao *contentsDao = [geoPackage contentsDao];
            SFPGeometryTransform *transform = [SFPGeometryTransform transformFromProjection:[[contentsDao srs:contents] projection] andToProjection:[tileMatrixSetSrs projection]];
            GPKGBoundingBox *transformedContentsBoundingBox = contentsBoundingBox;
            if(![transform isSameProjection]){
                transformedContentsBoundingBox = [transformedContentsBoundingBox transform:transform];
            }
            [transform destroy];
            displayBoundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:displayBoundingBox andBoundingBox:transformedContentsBoundingBox];
        }
        
        [self updateTileBoundingBox:displayBoundingBox withSrs:tileMatrixSetSrs andSpecifiedBoundingBox:nil];
        
    } @catch(NSException *e) {
        NSLog(@"MCTileHelper - createOverlayForTilesFromGeoPacakge %@", e.reason);
    } @finally {
        return overlay;
    }
    
}



-(void) updateTileBoundingBox: (GPKGBoundingBox *) dataBoundingBox withSrs: (GPKGSpatialReferenceSystem *) srs andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{

    GPKGBoundingBox * boundingBox = dataBoundingBox;
    if(boundingBox != nil){
        boundingBox = [self transformBoundingBoxToWgs84:boundingBox withSrs:srs];
    }else{
        boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-PROJ_WGS84_HALF_WORLD_LON_WIDTH andMinLatitudeDouble:PROJ_WEB_MERCATOR_MIN_LAT_RANGE andMaxLongitudeDouble:PROJ_WGS84_HALF_WORLD_LON_WIDTH andMaxLatitudeDouble:PROJ_WEB_MERCATOR_MAX_LAT_RANGE];
    }
    
    if(specifiedBoundingBox != nil){
        boundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        self.tilesBoundingBox = [GPKGTileBoundingBoxUtils unionWithBoundingBox:self.tilesBoundingBox andBoundingBox:boundingBox];
    }
}


- (GPKGBoundingBox *)transformBoundingBoxToWgs84: (GPKGBoundingBox *)boundingBox withSrs: (GPKGSpatialReferenceSystem *)srs {
    
    PROJProjection *projection = [srs projection];
    if([projection isUnit:PROJ_UNIT_DEGREES]){
        boundingBox = [GPKGTileBoundingBoxUtils boundDegreesBoundingBoxWithWebMercatorLimits:boundingBox];
    }
    SFPGeometryTransform *transformToWebMercator = [SFPGeometryTransform transformFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
    GPKGBoundingBox *webMercatorBoundingBox = [boundingBox transform:transformToWebMercator];
    [transformToWebMercator destroy];
    SFPGeometryTransform *transform = [SFPGeometryTransform transformFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    boundingBox = [webMercatorBoundingBox transform:transform];
    [transform destroy];
    return boundingBox;
}


-(GPKGBoundingBox *) tilesBoundingBox; {
    return _tilesBoundingBox;
}

@end
