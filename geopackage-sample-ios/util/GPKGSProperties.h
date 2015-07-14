//
//  GPKGSProperties.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/7/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKGSProperties : NSObject

+(NSString *) getValueOfProperty: (NSString *) property;

+(NSNumber *) getNumberValueOfProperty: (NSString *) property;

+(NSArray *) getArrayOfProperty: (NSString *) property;

+(NSDictionary *) getDictionaryOfProperty: (NSString *) property;

@end
