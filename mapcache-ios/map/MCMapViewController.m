//
//  MCMapViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapViewController.h"
#import "mapcache_ios-Swift.h"

@interface MCMapViewController ()
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@property (nonatomic, strong) NSUserDefaults *settings;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSMutableDictionary *geoPackages;
@property (nonatomic, strong) MCTileHelper *tileHelper;
@property (nonatomic, strong) MCFeatureHelper *featureHelper;
@property (nonatomic, strong) NSMutableDictionary *featureDaos;
@property (nonatomic, strong) GPKGBoundingBox *featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox *tilesBoundingBox;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL showingUserLocation;
@property (nonatomic) NSInteger userLocationStatus;
@property (nonatomic) BOOL featureOverlayTiles;
@property (nonatomic) BOOL ignoreRegionChange;
@property (atomic) int updateCountId;
@property (atomic) int featureUpdateCountId;
@property (nonatomic, strong) GPKGFeatureShapes *featureShapes;
@property (nonatomic) BOOL needsInitialZoom;
@property (nonatomic, strong) UIColor *boundingBoxColor;
@property (nonatomic) double boundingBoxLineWidth;
@property (nonatomic, strong) UIColor *boundingBoxFillColor;
@property (nonatomic, strong) UIColor *defaultPolylineColor;
@property (nonatomic) double defaultPolylineLineWidth;
@property (nonatomic, strong) UIColor *defaultPolygonColor;
@property (nonatomic) double defaultPolygonLineWidth;
@property (nonatomic, strong) UIColor *defaultPolygonFillColor;
@property (nonatomic, strong) UIColor *editPolylineColor;
@property (nonatomic) double editPolylineLineWidth;
@property (nonatomic, strong) UIColor *editPolygonColor;
@property (nonatomic) double editPolygonLineWidth;
@property (nonatomic, strong) UIColor *editPolygonFillColor;
@property (nonatomic, strong) UIColor *drawPolylineColor;
@property (nonatomic) double drawPolylineLineWidth;
@property (nonatomic, strong) UIColor *drawPolygonColor;
@property (nonatomic) double drawPolygonLineWidth;
@property (nonatomic, strong) UIColor *drawPolygonFillColor;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@property (nonatomic, strong) GPKGPolygon *boundingBox;
@property (nonatomic) CLLocationCoordinate2D boundingBoxStartCorner;
@property (nonatomic) CLLocationCoordinate2D boundingBoxEndCorner;
@property (nonatomic) double minLat;
@property (nonatomic) double maxLat;
@property (nonatomic) double minLon;
@property (nonatomic) double maxLon;
@property (nonatomic) BOOL settingsDrawerVisible;
@property (nonatomic) int currentZoom;
@property (nonatomic) CLLocationCoordinate2D currentCenter;
@property (nonatomic) BOOL expandedZoomDetails;
@property (nonatomic, strong) MKTileOverlay *userTileOverlay;
@property (nonatomic, strong) MKTileOverlay *bookmarkOverlay;
@property (nonatomic, strong) MKTileOverlay *userBasemapOverlay;
@property (nonatomic, strong) MKTileOverlay *gridOverlay;
@property (nonatomic) enum MCGridType gridType;
@end

enum MCGridType{
    MC_GT_NONE,
    MC_GT_GARS,
    MC_GT_MGRS
};

@implementation MCMapViewController

static NSString *mapPointImageReuseIdentifier = @"mapPointImageReuseIdentifier";
static NSString *mapPointPinReuseIdentifier = @"mapPointPinReuseIdentifier";

typedef NS_ENUM(NSInteger, MCLocationStatus) {
    MCLocationStatusNone,
    MCLocationStatusGPS,
    MCLocationStatusHeading
};

- (void)viewDidLoad {
    [super viewDidLoad];
    _childCoordinators = [[NSMutableArray alloc] init];

    self.mapView.delegate = self;
    self.mapView.showsCompass = NO;
    UIScreen *screen = [UIScreen mainScreen];
    self.mapView.frame = CGRectMake(0, 0, screen.bounds.size.width, screen.bounds.size.height);
    [self setupColors];
    self.settings = [NSUserDefaults standardUserDefaults];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    self.featureShapes = [[GPKGFeatureShapes alloc] init];
    self.featureDaos = [[NSMutableDictionary alloc] init];
    self.manager = [GPKGGeoPackageFactory manager];
    self.active = [MCDatabases getInstance];
    self.needsInitialZoom = true;
    self.updateCountId = 0;
    self.featureUpdateCountId = 0;
    [self.active setModified:YES];
    self.tileHelper = [[MCTileHelper alloc] initWithTileHelperDelegate:self];
    self.featureHelper = [[MCFeatureHelper alloc] initWithFeatureHelperDelegate:self];

    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.showingUserLocation = NO;
    self.userLocationStatus = MCLocationStatusNone;
    self.settingsDrawerVisible = NO;
    self.ignoreRegionChange = YES;
    self.currentZoom = -1;
    self.currentCenter = self.mapView.centerCoordinate;

    self.infoButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.infoButton.layer.shadowOpacity = 0.3;
    self.infoButton.layer.shadowRadius = 2;
    self.infoButton.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.infoButton.layer.cornerRadius = 8;
    self.infoButton.layer.maskedCorners = UIRectCornerTopLeft | UIRectCornerTopRight;

    self.locationButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.locationButton.layer.shadowOpacity = 0.3;
    self.locationButton.layer.shadowRadius = 2;
    self.locationButton.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.locationButton.layer.cornerRadius = 8;
    self.locationButton.layer.maskedCorners = UIRectCornerBottomLeft | UIRectCornerBottomRight;


    self.zoomIndicatorButton.backgroundColor = [UIColor clearColor];
    int zoom = [GPKGMapUtils currentRoundedZoomWithMapView:self.mapView];
    [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"%d", zoom] forState:UIControlStateNormal];
    self.zoomIndicatorButton.layer.cornerRadius = 8;
    self.zoomIndicatorButton.layer.maskedCorners = UIRectCornerTopRight | UIRectCornerBottomRight;
    self.expandedZoomDetails = NO;
    [self.zoomIndicatorButton setHidden:[_settings boolForKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR]];

    self.coordinateButton.backgroundColor = [UIColor clearColor];
    self.coordinateButton.layer.cornerRadius = 8.0;
    
    [self.view setNeedsLayout];

    self.boundingBoxMode = NO;
    [_mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget: self action:@selector(longPressGesture:)]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableBoundingBoxMode) name:@"drawBoundingBox" object:nil];
    self.tempMapPoints = [[NSMutableArray alloc] init];

    NSString *mapType = [self.settings stringForKey:GPKGS_PROP_MAP_TYPE];
    if (mapType == nil || [mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD]]) {
        [self.mapView setMapType:MKMapTypeStandard];
    } else if ([mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE]]) {
        [self.mapView setMapType:MKMapTypeSatellite];
    } else {
        [self.mapView setMapType:MKMapTypeHybrid];
    }

    self.bookmarkOverlay = [[MKTileOverlay alloc] init];
    [self.mapView addOverlay:_bookmarkOverlay];
    
    [[MCMetrics shared] showMap];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.active.modified) {
        [self.active setModified:NO];
        [self updateInBackgroundWithZoom:NO];
    }

    // iOS 13 dark mode support
    if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
        [self.zoomIndicatorButton setBackgroundColor:[UIColor colorNamed:@"ngaBackgroundColor"]];
        [self.coordinateButton setBackgroundColor:[UIColor colorNamed:@"ngaBackgroundColor"]];
        [self.locationButton setBackgroundColor:[UIColor colorNamed:@"ngaBackgroundColor"]];
        [self.infoButton setBackgroundColor:[UIColor colorNamed:@"ngaBackgroundColor"]];
    } else {

    }

    NSString *gridTypeName = [self.settings stringForKey:GPKGS_PROP_GRID_TYPE];

    enum MCGridType gridType = [self gridType:gridTypeName];
    if (gridType != -1) {

        _gridType = gridType;

        switch (gridType) {
            case MC_GT_GARS:
                _gridOverlay = [GridSystems garsTileOverlay];
                break;
            case MC_GT_MGRS:
                _gridOverlay = [GridSystems mgrsTileOverlay];
                break;
            default:
                break;
        }

        [self updateCoordinateLabel];
        if(_gridOverlay != nil) {
            [self.mapView addOverlay:_gridOverlay];
        }

    }

}


- (void)layoutSubviews {
    CAShapeLayer * topCornersMaskLayer = [CAShapeLayer layer];
    topCornersMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.infoButton.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){8.0, 8.0}].CGPath;

    self.infoButton.layer.mask = topCornersMaskLayer;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) zoomToPointWithOffset:(CLLocationCoordinate2D) point {
    point.latitude -= self.mapView.region.span.latitudeDelta * (1.0/3.0);
    [self.mapView setCenterCoordinate:point animated:YES];
}


- (void) zoomToPointWithOffset:(CLLocationCoordinate2D) point zoomLevel:(NSUInteger)zoomLevel {
    //point.latitude -= self.mapView.region.span.latitudeDelta * (1.0/3.0);
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*self.mapView.frame.size.width/256);
    [self.mapView setRegion:MKCoordinateRegionMake(point, span) animated:YES];

    /*if (self.expandedZoomDetails) {
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"Zoom level %d",  [GPKGMapUtils currentRoundedZoomWithMapView:self.mapView]] forState:UIControlStateNormal];
    } else {
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"%d",  [GPKGMapUtils currentRoundedZoomWithMapView:self.mapView]] forState:UIControlStateNormal];
    }*/
}


- (void)clearTempPoints {
    for (GPKGMapPoint *point in self.tempMapPoints) {
        [self.mapView removeAnnotation:point];
    }

    [self.tempMapPoints removeAllObjects];
}


- (void) removeMapPoint:(GPKGMapPoint *) mapPoint {
    [self.mapView removeAnnotation:mapPoint];
}



#pragma mark - Button actions
- (IBAction)showInfo:(id)sender {
    NSLog(@"MCMapController - Showing info drawer.");

    if (!self.settingsDrawerVisible) {
        self.settingsDrawerVisible = YES;
        [self.mapActionDelegate showMapInfoDrawer];
    }
}


- (IBAction)changeLocationState:(id)sender {
    NSLog(@"MCMapController - GPS button tapped");

    if (![CLLocationManager locationServicesEnabled]) {
        // todo show a message asking the user to enable it
        return;
    }

    if (self.userLocationStatus == MCLocationStatusNone) {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self.locationManager startUpdatingLocation];
                [self.locationButton setImage:[UIImage imageNamed:@"GPSActive"] forState:UIControlStateNormal];
                self.showingUserLocation = YES;
                self.userLocationStatus = MCLocationStatusGPS;
                break;
            default:
                self.showingUserLocation = NO;
                [self.locationManager requestWhenInUseAuthorization];
                break;
        }
    } else if (self.userLocationStatus == MCLocationStatusGPS) {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self.locationManager startUpdatingLocation];
                [self.locationManager startUpdatingHeading];
                [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
                [self.locationButton setImage:[UIImage imageNamed:@"GPSHeading"] forState:UIControlStateNormal];
                self.showingUserLocation = YES;
                self.userLocationStatus = MCLocationStatusHeading;
                break;
            default:
                self.showingUserLocation = NO;
                [self.locationManager requestWhenInUseAuthorization];
                break;
        }
    } else if (self.userLocationStatus == MCLocationStatusHeading) {
        self.userLocationStatus = MCLocationStatusNone;
        [self.locationManager stopUpdatingLocation];
        self.mapView.showsUserLocation = NO;
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
        self.showingUserLocation = NO;
        [self.locationButton setImage:[UIImage imageNamed:@"GPS"] forState:UIControlStateNormal];
    }
}


- (IBAction)toggleZoomDetails:(id)sender {
    int zoom = [GPKGMapUtils currentRoundedZoomWithMapView:self.mapView];

    if (self.expandedZoomDetails) {
        self.expandedZoomDetails = NO;
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"%d", zoom] forState:UIControlStateNormal];
        self.zoomIndicatorButtonWidth.constant = 30;

        CGRect buttonFrame = self.zoomIndicatorButton.frame;
        self.zoomIndicatorButton.frame = CGRectMake(buttonFrame.origin.x, buttonFrame.origin.y, 30, buttonFrame.size.height);

        [UIView animateWithDuration:0.15 animations:^{
            [self.zoomIndicatorButton layoutIfNeeded];
        }];
    } else {
        self.expandedZoomDetails = YES;
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"Zoom level %d", zoom] forState:UIControlStateNormal];
        self.zoomIndicatorButtonWidth.constant = 130;
        CGRect buttonFrame = self.zoomIndicatorButton.frame;
        self.zoomIndicatorButton.frame = CGRectMake(buttonFrame.origin.x, buttonFrame.origin.y, 130, buttonFrame.size.height);

        [UIView animateWithDuration:0.15 animations:^{
            [self.zoomIndicatorButton layoutIfNeeded];
        }];
    }

}


#pragma mark - Updaing the data on the map
- (void) updateMapLayers {
    [self updateInBackgroundWithZoom:YES];
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *userLocation = [locations lastObject];

    if (self.showingUserLocation && !self.mapView.showsUserLocation && userLocation.coordinate.latitude != 0.0) {
        self.mapView.showsUserLocation = YES;
        [self zoomToPointWithOffset:_locationManager.location.coordinate zoomLevel:15];
    } else if (self.showingUserLocation) {
        self.mapView.showsUserLocation = YES;
    } else {
        self.mapView.showsUserLocation = NO;
    }
}


#pragma mark - MCMapSettingsDelegate
- (void)setMapType:(NSString *)mapType {
    NSLog(@"MCMapController -  handing setting map change");

    if ([mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD]]) {
        [self.mapView setMapType:MKMapTypeStandard];
        [self.settings setObject:mapType forKey:GPKGS_PROP_MAP_TYPE];
    } else if ([mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE]]) {
        [self.mapView setMapType:MKMapTypeSatellite];
        [self.settings setObject:mapType forKey:GPKGS_PROP_MAP_TYPE];
    } else if ([mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_HYBRID]]) {
        [self.mapView setMapType:MKMapTypeHybrid];
        [self.settings setObject:mapType forKey:GPKGS_PROP_MAP_TYPE];
    } else {
        enum MCGridType gridType = [self gridType:mapType];
        if (gridType != -1) {

            _gridType = gridType;

            if (_gridOverlay != nil) {
                [self.mapView removeOverlay:_gridOverlay];
                _gridOverlay = nil;
            }

            switch (gridType) {
                case MC_GT_GARS:
                    _gridOverlay = [GridSystems garsTileOverlay];
                    break;
                case MC_GT_MGRS:
                    _gridOverlay = [GridSystems mgrsTileOverlay];
                    break;
                default:
                    break;
            }

            [self updateCoordinateLabel];
            if(_gridOverlay != nil) {
                [self.mapView addOverlay:_gridOverlay];
            }
            [self.settings setObject:mapType forKey:GPKGS_PROP_GRID_TYPE];
        }
    }

    NSLog(@"MCMapController - NSUSerDefaults\n %@", [self.settings dictionaryRepresentation]);
}


- (void)updateBasemaps:(NSString *)url serverType:(MCTileServerType) serverType {
    NSLog(@"MCMapController - updateBasemaps");
    @try {
        if (self.userBasemapOverlay != nil) {
            [self.mapView removeOverlay:self.userBasemapOverlay];
        }

        if (url == nil || [url isEqualToString: @""]) {
            return;
        }

        if (serverType == MCTileServerTypeXyz) {
            self.userBasemapOverlay = [[MKTileOverlay alloc] initWithURLTemplate:url];
            [self.mapView insertOverlay:self.userBasemapOverlay atIndex:0];
        } else if (serverType == MCTileServerTypeWms) {
            self.userBasemapOverlay = [[WMSTileOverlay alloc] initWithURL:url];
            [self.mapView insertOverlay:self.userBasemapOverlay atIndex:0];
        }
    } @catch(NSException *e) {
        NSLog(@"Tile loading problem");
    }
}


- (void)setMaxFeatures:(int) maxFeatures {
    [self.settings setInteger:maxFeatures forKey:GPKGS_PROP_MAP_MAX_FEATURES];
    [self updateInBackgroundWithZoom:YES];
}


- (void)settingsCompletionHandler {
    self.settingsDrawerVisible = NO;
}


- (void) toggleZoomIndicator {
    [self.zoomIndicatorButton setHidden:[self.settings boolForKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR]];
}


- (void) toggleMapControls {
    if ([self.zoomIndicatorButton isHidden]) {
        [self.zoomIndicatorButton setHidden:NO];
    } else {
        [self.zoomIndicatorButton setHidden:[self.settings boolForKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR]];
    }

    if ([self.infoButton isHidden]) {
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.infoButton setHidden:NO];
            [self.locationButton setHidden:NO];
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.infoButton setHidden:YES];
            [self.locationButton setHidden:YES];
        } completion:nil];
    }
}

#pragma mark - MCTileHelperDelegate methods
- (void)addTileOverlayToMapView:(MKTileOverlay *)tileOverlay withTable:(MCTileTable *)table {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView insertOverlay:tileOverlay belowOverlay:self.bookmarkOverlay];
    });
}


#pragma mark - MCFeatureHelperDelegate methods
- (void) addShapeToMapView:(GPKGMapShape *) shape withCount:(int) count {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
        //[self.mapView insertOverlay:self.bookmarkOverlay aboveOverlay:shape];

        switch (shape.shapeType) {

                case GPKG_MST_POINT:
                    [self.mapView addAnnotation:(GPKGMapPoint *)shape.shape];
                    break;
                case GPKG_MST_POLYLINE:
                    [self.mapView insertOverlay:(GPKGPolyline *)shape.shape aboveOverlay:self.bookmarkOverlay];
                    break;
                case GPKG_MST_POLYGON:
                    [self.mapView insertOverlay:(GPKGPolygon *)shape.shape aboveOverlay:self.bookmarkOverlay];
                    break;
                case GPKG_MST_MULTI_POINT:
                    for (GPKGMapPoint *point in ((GPKGMultiPoint *)shape.shape).points) {
                        [self.mapView addAnnotation:point];
                    }
                    break;
                case GPKG_MST_MULTI_POLYLINE:
                    for (GPKGPolyline *polyline in ((GPKGMultiPoint *)shape.shape).points) {
                        [self.mapView insertOverlay:polyline aboveOverlay:self.bookmarkOverlay];
                    }
                    break;
                case GPKG_MST_MULTI_POLYGON:
                    for (GPKGPolygon *polygon in ((GPKGMultiPolygon *)shape.shape).polygons) {
                        [self.mapView insertOverlay:polygon aboveOverlay:self.bookmarkOverlay];
                    }
                    break;
                /*case GPKG_MST_COLLECTION:
                    {
                        NSMutableArray * addedShapeArray = [NSMutableArray array];
                        NSArray * shapeArray = (NSArray *) mapShape.shape;
                        for(GPKGMapShape * shapeArrayItem in shapeArray){
                            [GPKGUtils addObject:[self addMapShape:shapeArrayItem toMapView:mapView] toArray:addedShapeArray];
                        }
                        addedShape = [[GPKGMapShape alloc] initWithGeometryType:mapShape.geometryType andShapeType:GPKG_MST_COLLECTION andShape:addedShapeArray];
                    }
                    break;*/
                default:
                    [NSException raise:@"Unsupported Shape" format:@"Unsupported Shape Type: %@", [GPKGMapShapeTypes name:shape.shapeType]];
            }
    });
}


- (void) showMaxFeaturesWarning {

    dispatch_sync(dispatch_get_main_queue(), ^{
        BOOL hideWarning = [self.settings boolForKey:GPKGS_PROP_HIDE_MAX_FEATURES_WARNING];
        if (hideWarning) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Max features exceeded" message:@"In the app settings you can adjust how many features you display on the map." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            }];

            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}


#pragma mark - MKMapViewDelegate methods
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        UIColor *strokeColor = self.defaultPolygonColor;
        double lineWidth = self.defaultPolygonLineWidth;
        UIColor *fillColor = self.defaultPolygonFillColor;
        if ([overlay isKindOfClass:[GPKGPolygon class]]) {
            GPKGPolygon *polygon = (GPKGPolygon *) overlay;
            GPKGPolygonOptions *options = polygon.options;
            if(options != nil){
                if(options.strokeColor != nil){
                    strokeColor = options.strokeColor;
                    fillColor = nil;
                }
                if(options.lineWidth > 0){
                    lineWidth = options.lineWidth;
                }
                if(options.fillColor != nil){
                    fillColor = options.fillColor;
                }
            }
        }
        polygonRenderer.strokeColor = strokeColor;
        polygonRenderer.lineWidth = lineWidth;
        if(fillColor != nil){
            polygonRenderer.fillColor = fillColor;
        }
        rendered = polygonRenderer;
    }else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        UIColor *strokeColor = self.defaultPolylineColor;
        double lineWidth = self.defaultPolylineLineWidth;
        if ([overlay isKindOfClass:[GPKGPolyline class]]) {
            GPKGPolyline *polyline = (GPKGPolyline *) overlay;
            GPKGPolylineOptions *options = polyline.options;
            if(options != nil){
                if(options.strokeColor != nil){
                    strokeColor = options.strokeColor;
                }
                if(options.lineWidth > 0){
                    lineWidth = options.lineWidth;
                }
            }
        }
        polylineRenderer.strokeColor = strokeColor;
        polylineRenderer.lineWidth = lineWidth;
        rendered = polylineRenderer;
    }else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        rendered = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return rendered;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView * view = nil;

    if ([annotation isKindOfClass:[GPKGMapPoint class]]){
        GPKGMapPoint * mapPoint = (GPKGMapPoint *) annotation;

        if(mapPoint.options.image != nil){

            MKAnnotationView *mapPointImageView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointImageReuseIdentifier];
            if (mapPointImageView == nil)
            {
                mapPointImageView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:mapPointImageReuseIdentifier];
            }
            mapPointImageView.image = mapPoint.options.image;
            mapPointImageView.centerOffset = mapPoint.options.imageCenterOffset;

            view = mapPointImageView;
            mapPoint.view = view;
        }else{
            MKMarkerAnnotationView *annotationView = (MKMarkerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointPinReuseIdentifier];
            if (annotationView == nil) {
                annotationView = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:mapPointPinReuseIdentifier];
            }
            annotationView.tintColor = mapPoint.options.pinTintColor;
            view = annotationView;
        }

        if(mapPoint.title == nil){
            [self.featureHelper setTitleWithMapPoint:mapPoint];
        }

        //UIButton *optionsButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        //[optionsButton addTarget:self action:@selector(selectedMapPointOptions:) forControlEvents:UIControlEventTouchUpInside];

        //view.rightCalloutAccessoryView = optionsButton;
        view.canShowCallout = YES;

        view.draggable = mapPoint.options.draggable;
    }

    return view;
}


- (void)mapViewDidChangeVisibleRegion:(MKMapView *)mapView {
    if (self.expandedZoomDetails) {
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"Zoom level %d", [GPKGMapUtils currentRoundedZoomWithMapView:mapView]] forState:UIControlStateNormal];
    } else {
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"%d", [GPKGMapUtils currentRoundedZoomWithMapView:mapView]] forState:UIControlStateNormal];
    }
}


-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{

    [self updateCoordinateLabel];
    
    if (_active == nil) {
        return;
    }

    if (self.ignoreRegionChange) {
        self.ignoreRegionChange = NO;
        return;
    }

    CLLocationCoordinate2D previousCenter = self.currentCenter;
    self.currentCenter = self.mapView.centerCoordinate;
    int previousZoom = self.currentZoom;
    self.currentZoom = [GPKGMapUtils currentRoundedZoomWithMapView:mapView];

    if (self.currentCenter.latitude == previousCenter.latitude && self.currentCenter.longitude == previousCenter.longitude && self.currentZoom == previousZoom) {
        return;
    }

    if (self.expandedZoomDetails) {
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"Zoom level %d", self.currentZoom] forState:UIControlStateNormal];
    } else {
        [self.zoomIndicatorButton setTitle:[NSString stringWithFormat: @"%d", self.currentZoom] forState:UIControlStateNormal];
    }

    if (self.currentZoom != previousZoom) {
        // Zoom level changed, remove all the feature shapes except the markers
        [self.featureHelper.featureShapes removeShapesFromMapView:mapView withExclusions:[[NSSet alloc] initWithObjects:[NSNumber numberWithInt:GPKG_MST_POINT], [NSNumber numberWithInt:GPKG_MST_MULTI_POINT], nil]];
    } else {
        // Remove shapes no longer visible on the map view
        [self.featureHelper.featureShapes removeShapesNotWithinMapView:mapView];
    }

    int updateId = [self.featureHelper getNewUpdateId];
    int featureUpdateId = [self.featureHelper getNewFeatureUpdateId];
    [self.featureHelper resetFeatureCount];

    GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:mapView];
    double toleranceDistance = [GPKGMapUtils toleranceDistanceInMapView:mapView];
    int maxFeatures = [self getMaxFeatures];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
         if (self.active != nil) {
            for (MCDatabase *database in [self.active getDatabases]) {
                GPKGGeoPackage *geoPacakge;
                @try {
                    geoPacakge = [self.manager open:database.name];
                    //[self.tileHelper prepareTilesForGeoPackage:geoPacakge andDatabase:database];

                    [self.featureHelper prepareFeaturesWithGeoPackage:geoPacakge andDatabase:database andUpdateId: (int)updateId andFeatureUpdateId: (int)featureUpdateId andZoom: (int)self.currentZoom andMaxFeatures: (int)maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *)mapViewBoundingBox andToleranceDistance: (double)toleranceDistance andFilter: YES];

                } @catch (NSException *exception) {
                   NSLog(@"MCMapController - Error reading geopackage %@, error: %@", database, [exception description]);
                }
            }
        }
    });
}


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"MCMapController - Tapped map point");

    if ([view.annotation isKindOfClass:MKUserLocation.class]) {
        return;
    }
    
    if ([view isKindOfClass:MKAnnotationView.class] || [view isKindOfClass:MKMarkerAnnotationView.class]) {
        [self zoomToPointWithOffset:view.annotation.coordinate];
        [self.mapActionDelegate showDetailsForAnnotation:(GPKGMapPoint *)view.annotation];
    }
}


#pragma mark - Zoom and map state
-(void) updateInBackgroundWithZoom: (BOOL) zoom{
    [self updateInBackgroundWithZoom:zoom andFilter:false];
}


-(void) updateInBackgroundWithZoom: (BOOL) zoom andFilter: (BOOL) filter{
    int updateId = [self.featureHelper getNewUpdateId];
    int featureUpdateId = [self.featureHelper getNewFeatureUpdateId];
    [self.featureHelper resetFeatureCount];
    [self.mapView removeAnnotations:self.mapView.annotations];
    for (id<MKOverlay> overlay in self.mapView.overlays) {
        if ([overlay isKindOfClass:[GPKGBoundedOverlay class]]) {
            [(GPKGBoundedOverlay *)overlay close];
        }
    }
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView addOverlay:self.bookmarkOverlay];

    if (self.userBasemapOverlay != nil) {
        [self.mapView addOverlay:self.userBasemapOverlay];
    }

    for(GPKGGeoPackage * geoPackage in [self.geoPackages allValues]){
        @try {
            [geoPackage close];
        }
        @catch (NSException *exception) {
        }
    }
    [self.geoPackages removeAllObjects];
    [self.featureDaos removeAllObjects];

    if(zoom){
        self.ignoreRegionChange = YES;
        [self zoomToActiveBounds];
    }

    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    self.featureOverlayTiles = false;
    [self.featureHelper.featureShapes clear];

    int maxFeatures = [self getMaxFeatures];
    GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:self.mapView];
    double toleranceDistance = [GPKGMapUtils toleranceDistanceInMapView:self.mapView];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
         if (self.active != nil) {
             for (MCDatabase *database in [self.active getDatabases]) {
                 GPKGGeoPackage *geoPacakge;
                 @try {
                     geoPacakge = [self.manager open:database.name];
                     if(geoPacakge != nil) {
                         [self.tileHelper prepareTilesForGeoPackage:geoPacakge andDatabase:database];
                         
                         [self.featureHelper prepareFeaturesWithGeoPackage:geoPacakge andDatabase:database andUpdateId: (int)updateId andFeatureUpdateId: (int)featureUpdateId andZoom: (int)zoom andMaxFeatures: (int)maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *)mapViewBoundingBox andToleranceDistance: (double)toleranceDistance andFilter:(BOOL) filter];
                     }
                 } @catch (NSException *exception) {
                    NSLog(@"MCMapController - Error reading geopackage %@, error: %@", database, [exception description]);
                 }
             }
         }
    });
}


-(void) updateFeaturesBoundingBox: (GPKGMapShape *) shape
{
    if(self.featuresBoundingBox != nil){
        [shape expandBoundingBox:self.featuresBoundingBox];
    }else{
        self.featuresBoundingBox = [shape boundingBox];
    }
}


-(void) zoomToActive{
    [self zoomToActiveIfNothingVisible:NO];
}


-(void) zoomToActiveAndIgnoreRegionChange: (BOOL) ignoreChange{
    [self zoomToActiveIfNothingVisible:NO andIgnoreRegionChange:ignoreChange];
}


-(void) zoomToActiveIfNothingVisible: (BOOL) nothingVisible{
    [self zoomToActiveIfNothingVisible:nothingVisible andIgnoreRegionChange:NO];
}


-(void) zoomToActiveIfNothingVisible: (BOOL) nothingVisible andIgnoreRegionChange: (BOOL) ignoreChange{
    GPKGBoundingBox * bbox = self.featuresBoundingBox;
    BOOL tileBox = false;

    float paddingPercentage;
    if(bbox == nil){
        bbox = self.tilesBoundingBox;
        tileBox = true;
        if(self.featureOverlayTiles){
            paddingPercentage = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURE_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }else{
            paddingPercentage = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }
    }else{
        paddingPercentage = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_PADDING_PERCENTAGE] intValue] * .01f;
    }

    if(bbox != nil){

        BOOL zoomToActive = YES;
        if(nothingVisible){
            GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:self.mapView];
            if([GPKGTileBoundingBoxUtils overlapWithBoundingBox:bbox andBoundingBox:mapViewBoundingBox withMaxLongitude:PROJ_WGS84_HALF_WORLD_LON_WIDTH] != nil){

                struct GPKGBoundingBoxSize bboxSize = [bbox sizeInMeters];
                struct GPKGBoundingBoxSize mapViewSize = [mapViewBoundingBox sizeInMeters];

                double longitudeDistance = bboxSize.width;
                double latitudeDistance = bboxSize.height;
                double mapViewLongitudeDistance = mapViewSize.width;
                double mapViewLatitudeDistance = mapViewSize.height;

                if (mapViewLongitudeDistance > longitudeDistance && mapViewLatitudeDistance > latitudeDistance) {

                    double longitudeRatio = longitudeDistance / mapViewLongitudeDistance;
                    double latitudeRatio = latitudeDistance / mapViewLatitudeDistance;

                    double zoomAlreadyVisiblePercentage;
                    if (tileBox) {
                        zoomAlreadyVisiblePercentage = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_ALREADY_VISIBLE_PERCENTAGE] intValue] * .01;
                    }else{
                        zoomAlreadyVisiblePercentage = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_ALREADY_VISIBLE_PERCENTAGE] intValue] * .01;
                    }

                    if(longitudeRatio >= zoomAlreadyVisiblePercentage && latitudeRatio >= zoomAlreadyVisiblePercentage){
                        zoomToActive = false;
                    }
                }
            }
        }

        if(zoomToActive){
            struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
            double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
            double expandedWidth = size.width + (2 * (size.width * paddingPercentage));

            CLLocationCoordinate2D center = [bbox center];
            MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);

            double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;

            if(expandedRegion.center.latitude + latitudeRange > 90.0 || expandedRegion.center.latitude - latitudeRange < -90.0){
                expandedRegion = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
            }

            if(ignoreChange){
                self.ignoreRegionChange = YES;
            }
            [self.mapView setRegion:expandedRegion animated:true];
        }
    }
}


-(void) zoomToActiveBounds{
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;

    // Pre zoom
    NSMutableArray *activeDatabase = [[NSMutableArray alloc] init];
    [activeDatabase addObjectsFromArray:[self.active getDatabases]];
    for(MCDatabase *database in activeDatabase){
        GPKGGeoPackage *geoPackage;

        @try {
            geoPackage = [self.manager open:database.name];
            if (geoPackage != nil) {
                NSMutableSet<NSString *> *featureTableDaos = [[NSMutableSet alloc] init];
                NSArray *features = [database getFeatures];

                if(features.count > 0){
                    for(MCTable *featureTable in features){
                        [featureTableDaos addObject:featureTable.name];
                    }
                }

                for(MCFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    if(featureOverlay.active){
                        [featureTableDaos addObject:featureOverlay.featureTable];
                    }
                }

                if(featureTableDaos.count > 0){
                    GPKGContentsDao *contentsDao = [geoPackage contentsDao];

                    for (NSString *featureTable in featureTableDaos) {
                        @try {
                            GPKGContents *contents = (GPKGContents *)[contentsDao queryForIdObject:featureTable];
                            GPKGBoundingBox *contentsBoundingBox = [contents boundingBox];

                            if (contentsBoundingBox != nil) {
                                contentsBoundingBox = [self.tileHelper transformBoundingBoxToWgs84: contentsBoundingBox withSrs: [contentsDao srs:contents]];

                                if (self.featuresBoundingBox != nil) {
                                    self.featuresBoundingBox = [self.featuresBoundingBox union:contentsBoundingBox];
                                } else {
                                    self.featuresBoundingBox = contentsBoundingBox;
                                }
                            }
                        } @catch (NSException *e) {
                            NSLog(@"MCMapController - Problem with features in zoomToActiveBounds: %@", [e description]);
                        } @finally {
                            [geoPackage close];
                        }
                    }
                }

                NSArray *tileTables = [database getTiles];
                if(tileTables.count > 0){

                    GPKGTileMatrixSetDao *tileMatrixSetDao = [geoPackage tileMatrixSetDao];

                    for(MCTileTable *tileTable in tileTables){

                        @try {
                            GPKGTileMatrixSet *tileMatrixSet = (GPKGTileMatrixSet *)[tileMatrixSetDao queryForIdObject:tileTable.name];
                            GPKGBoundingBox *tileMatrixSetBoundingBox = [tileMatrixSet boundingBox];

                            tileMatrixSetBoundingBox = [self.tileHelper transformBoundingBoxToWgs84:tileMatrixSetBoundingBox withSrs:[tileMatrixSetDao srs:tileMatrixSet]];

                            if (self.tilesBoundingBox != nil) {
                                self.tilesBoundingBox = [self.tilesBoundingBox union:tileMatrixSetBoundingBox];
                            } else {
                                self.tilesBoundingBox = tileMatrixSetBoundingBox;
                            }
                        } @catch (NSException *e) {
                            NSLog(@"MCMapController - Problem with tiles in zoomToActiveBounds%@", [e description]);
                        } @finally {
                            [geoPackage close];
                        }
                    }
                }
            }
        } @catch (NSException *e) {
            NSLog(@"MCMapController - Problem zooming to bounds %@", e.reason);
        } @finally {
            if (geoPackage != nil) {
                [geoPackage close];
            }
        }
    }

    [self zoomToActiveAndIgnoreRegionChange:YES];
}


-(int) getMaxFeatures{
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    return maxFeatures;
}


- (void) setupColors {
    self.boundingBoxColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_COLOR]];
    self.boundingBoxLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_LINE_WIDTH] doubleValue];
    if([MCProperties getBoolOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL]){
        self.boundingBoxFillColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL_COLOR]];
    }

    self.defaultPolylineColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYLINE_COLOR]];
    self.defaultPolylineLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_DEFAULT_POLYLINE_LINE_WIDTH] doubleValue];

    self.defaultPolygonColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYGON_COLOR]];
    self.defaultPolygonLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_DEFAULT_POLYGON_LINE_WIDTH] doubleValue];
    if([MCProperties getBoolOfProperty:GPKGS_PROP_DEFAULT_POLYGON_FILL]){
        self.defaultPolygonFillColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYGON_FILL_COLOR]];
    }

    self.editPolylineColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYLINE_COLOR]];
    self.editPolylineLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_EDIT_POLYLINE_LINE_WIDTH] doubleValue];

    self.editPolygonColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYGON_COLOR]];
    self.editPolygonLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_EDIT_POLYGON_LINE_WIDTH] doubleValue];
    if([MCProperties getBoolOfProperty:GPKGS_PROP_EDIT_POLYGON_FILL]){
        self.editPolygonFillColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYGON_FILL_COLOR]];
    }

    self.drawPolylineColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYLINE_COLOR]];
    self.drawPolylineLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYLINE_LINE_WIDTH] doubleValue];

    self.drawPolygonColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_COLOR]];
    self.drawPolygonLineWidth = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYGON_LINE_WIDTH] doubleValue];
    if([MCProperties getBoolOfProperty:GPKGS_PROP_DRAW_POLYGON_FILL]){
        self.drawPolygonFillColor = [GPKGUtils color:[MCProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_FILL_COLOR]];
    }
}


/**
   Used to show tile previews after a tile download, or switch on saved tile URLs from the map.
*/
- (void) addUserTilesWithUrl:(NSString *) tileTemplateURL serverType:(MCTileServerType)serverType {
    if (self.userTileOverlay != nil) {
        [self.mapView removeOverlay:self.userTileOverlay];
    }

    if (serverType == MCTileServerTypeXyz) {
        self.userTileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:tileTemplateURL];
    } else if (serverType == MCTileServerTypeWms) {
        self.userTileOverlay = [[WMSTileOverlay alloc] initWithURL:tileTemplateURL];
    }

    if (self.userTileOverlay != nil) {
        [self.mapView insertOverlay:self.userTileOverlay atIndex:0];
    }
}


- (void)addUserTileOverlay:(MKTileOverlay *)tileOverlay {
    if (self.userTileOverlay != nil) {
        [self.mapView removeOverlay:self.userTileOverlay];
    }

    self.userTileOverlay = tileOverlay;

    if (self.userTileOverlay != nil) {
        [self.mapView insertOverlay:self.userTileOverlay atIndex:0];
    }
}


/**
    Used to remove tile previews after a tile download, or switch off saved tile URLs from the map.
 */
- (void) removeUserTiles {
    if (self.userTileOverlay != nil) {
        [self.mapView removeOverlay:self.userTileOverlay];
    }
}


#pragma mark - Bounding Box methods for creating new tile layers
- (void) enableBoundingBoxMode {
    NSLog(@"MCMapController - going into bounding box mode");
    self.boundingBoxMode = YES;
}


-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer {
    NSLog(@"MCMapController - Getting a long press gesture.");

    if (!self.boundingBoxMode) {
        CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];

        if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan && self.tempMapPoints.count == 0) {
            UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];

            NSLog(@"MCMapController - Adding a pin");
            GPKGMapPoint * mapPoint = [[GPKGMapPoint alloc] initWithLocation:point];
            [mapPoint.options setPinTintColor:[UIColor redColor]];

            [self.mapView addAnnotation: mapPoint];
            [self.tempMapPoints addObject:mapPoint];

            if (!_drawing && self.tempMapPoints.count > 0) {
                [self zoomToPointWithOffset: point];
                [mapPoint setTitle:[_featureHelper buildLocationTitleWithMapPoint:mapPoint]];
                [self.mapView selectAnnotation:mapPoint animated:YES];

                _drawing = YES;
            } else {
                [self.mapActionDelegate updateDrawingStatus];
            }
        }
    }


    // MKMapView workaround for unresponsiveness after a longpress https://forums.developer.apple.com/thread/126473
    //[self.mapView setCenterCoordinate:self.mapView.centerCoordinate animated:NO];
}


-(BOOL) isWithinDistanceWithPoint: (CGPoint) point andLocation: (CLLocationCoordinate2D) location andAllowableScreenPercentage: (double) allowableScreenPercentage{

    CGPoint locationPoint = [self.mapView convertCoordinate:location toPointToView:self.mapView];
    double distance = sqrt(pow(point.x - locationPoint.x, 2) + pow(point.y - locationPoint.y, 2));

    BOOL withinDistance = distance / MIN(self.mapView.frame.size.width, self.mapView.frame.size.height) <= allowableScreenPercentage;
    return withinDistance;
}


- (CLLocationCoordinate2D) convertPointToCoordinate:(CGPoint) point {
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    return coordinate;
}


-(CLLocationCoordinate2D *) getPolygonPointsWithPoint1: (CLLocationCoordinate2D) point1 andPoint2: (CLLocationCoordinate2D) point2{
    CLLocationCoordinate2D *coordinates = calloc(4, sizeof(CLLocationCoordinate2D));
    coordinates[0] = CLLocationCoordinate2DMake(point1.latitude, point1.longitude);
    coordinates[1] = CLLocationCoordinate2DMake(point1.latitude, point2.longitude);
    coordinates[2] = CLLocationCoordinate2DMake(point2.latitude, point2.longitude);
    coordinates[3] = CLLocationCoordinate2DMake(point2.latitude, point1.longitude);
    return coordinates;
}


-(void) updateCoordinateLabel {
    if (_gridType != -1 && _gridType != MC_GT_NONE) {

        NSString *label = nil;

        CLLocationCoordinate2D center = self.mapView.centerCoordinate;
        switch (_gridType) {
            case MC_GT_GARS:
                label = [GridSystems gars:center];
                break;
            case MC_GT_MGRS:
                label = [GridSystems mgrs:center];
                break;
            default:
                break;
        }

        [self.coordinateButton setTitle:label forState:UIControlStateNormal];
        [self.coordinateButton setHidden:NO];

    } else {
        [self.coordinateButton setTitle:@"" forState:UIControlStateNormal];
        [self.coordinateButton setHidden:YES];
    }
}


-(enum MCGridType) gridType: (NSString *) name {
    enum MCGridType gridType = -1;
    if (name != nil) {
        if ([name isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_NONE]]) {
            gridType = MC_GT_NONE;
        } else if ([name isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_GARS]]) {
           gridType = MC_GT_GARS;
        } else if ([name isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_MGRS]]) {
           gridType = MC_GT_MGRS;
        }
    }
    return gridType;
}

@end
