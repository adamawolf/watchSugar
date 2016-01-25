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

@interface DefaultsController : NSObject

+ (void)addLogMessage:(NSString *)logMessage;

+ (NSArray <NSString *> *)allLogMessages;

+ (void)clearAllLogMessages;

+ (WSLoginStatus)lastKnownLoginStatus;
+ (void)setLastKnownLoginStatus:(WSLoginStatus)status;

+ (NSArray <NSDictionary *> *)latestBloodSugarReadings;

+ (NSString *)dexcomToken;
+ (void)setDexcomToken:(NSString *)dexcomToken;

@end
