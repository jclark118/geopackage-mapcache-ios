//
//  GPKGSColorUtil.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSColorUtil.h"

@implementation GPKGSColorUtil

+ (UIColor *) getPrimary {
    return [UIColor colorWithRed:0.0f green:0.31f blue:0.49f alpha:1];
}


+ (UIColor *) getPrimaryLight {
    return [UIColor colorWithRed:0.15f green:0.47f blue:0.61f alpha:1];
}


+ (UIColor *) getAccent {
    return [UIColor colorWithRed:0.28f green:0.69f blue:0.71f alpha:1];
}


+ (UIColor *) getAccentLight {
    return [UIColor colorWithRed:0.51f green:0.78f blue:0.8f alpha:1];
}

+ (UIColor *) getMediumGrey {
    return [UIColor colorWithRed:(229/255.0) green:(230/255.0) blue:(230/255.0) alpha:1];
}

@end
