//
//  WebRequestController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/12/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const WSNotificationDexcomDataChanged;
extern NSString *const WSDefaults_LastReadings;

@interface WebRequestController : NSObject

@property (nonatomic, strong) NSString *dexcomToken;
@property (nonatomic, strong) NSString *subscriptionId;
@property (nonatomic, strong) NSDictionary * latestBloodSugarData;

@property (nonatomic, strong) NSDate *lastFetchAttempt;

- (void)performFetchInBackground:(BOOL)inBackground;

@end
