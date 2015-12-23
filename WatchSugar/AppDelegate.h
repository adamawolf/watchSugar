//
//  AppDelegate.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const WSNotificationDexcomDataChanged;

typedef enum : NSUInteger {
    WSTrendValueDoubleUp = 1,
    WSTrendValueUp,
    WSTrendValueHalfUp,
    WSTrendValueFlat,
    WSTrendValueHalfDown,
    WSTrendValueDown,
    WSTrendValueDoubleDown,
} WSTrendValue;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) NSString *dexcomToken;
@property (nonatomic, strong) NSString *subscriptionId;
@property (nonatomic, strong) NSDictionary * latestBloodSugarData;

@property (nonatomic, assign) NSInteger backgroundFetchCount;
@property (nonatomic, strong) NSDate *lastBackgroundFetchDate;

@end

