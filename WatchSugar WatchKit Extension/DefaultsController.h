//
//  DefaultsLogController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/13/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthenticationController.h"

typedef NS_ENUM(NSUInteger, WSProcessReadingResult) {
    WSProcessReadingResultNewResultAdded,
    WSProcessReadingResultNothingChanged,
};

@interface DefaultsController : NSObject

+ (void)configureDefaults;

//blood sugar storage and retrieval
+ (NSArray <NSDictionary *> *)latestBloodSugarReadings;
+ (WSProcessReadingResult)processNewBloodSugarData:(NSDictionary *)prospectiveNewBloodSugarData;

//login status management
+ (WSLoginStatus)lastKnownLoginStatus;
+ (void)setLastKnownLoginStatus:(WSLoginStatus)status;

//global app settings
+ (BOOL)timeTravelEnabled;
+ (void)setTimeTravelEnabled:(BOOL)enabled;
+ (NSInteger)quietTimeStartHour;
+ (NSInteger)quietTimeEndHour;

//debug logging to user defaults for use in development
+ (void)addLogMessage:(NSString *)logMessage;
+ (NSArray <NSString *> *)allLogMessages;
+ (void)clearAllLogMessages;

@end
