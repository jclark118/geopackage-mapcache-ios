//
//  WMSTileOverlay.h
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMSTileOverlay : MKTileOverlay

- (id) initWithURL: (NSString *) url;
- (id) initWithURL:(NSString *) url username:(NSString *)username password:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
