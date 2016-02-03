//
//  DefaultsLogController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/13/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AuthenticationController.h"

extern NSString *const WSDefaults_LogMessageArray;
extern NSString *const WSDefaults_LastKnownLoginStatus;
extern NSString *const WSDefaults_LastReadings;
extern NSString *const WSDefaults_TimeTravelEnabled;

typedef NS_ENUM(NSUInteger, WSProcessReadingResult) {
    WSProcessReadingResultNewResultAdded,
    WSProcessReadingResultNothingChanged,
};

typedef NS_ENUM(NSUInteger, WSUserGroup) {
    WSUserGroupNone,
    WSUserGroupFirstWaveBetaTesters,
    WSUserGroupSecondWaveBetaTesters_NoTimeTravel,
    WSUserGroupSecondWaveBetaTesters_WithTimeTravel,
};

@interface DefaultsController : NSObject

+ (void)configureInitialOptions;

+ (void)addLogMessage:(NSString *)logMessage;

+ (NSArray <NSString *> *)allLogMessages;

+ (void)clearAllLogMessages;

+ (WSLoginStatus)lastKnownLoginStatus;
+ (void)setLastKnownLoginStatus:(WSLoginStatus)status;

+ (NSArray <NSDictionary *> *)latestBloodSugarReadings;

+ (WSProcessReadingResult)processNewBloodSugarData:(NSDictionary *)prospectiveNewBloodSugarData;

+ (BOOL)timeTravelEnabled;
+ (void)setTimeTravelEnabled:(BOOL)enabled;

@end
