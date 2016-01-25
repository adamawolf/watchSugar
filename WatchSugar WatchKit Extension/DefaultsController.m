//
//  DefaultsLogController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/13/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "DefaultsController.h"

NSString *const WSDefaults_LogMessageArray = @"WSDefaults_LogMessageArray";
NSString *const WSDefaults_LastKnownLoginStatus = @"WSDefaults_LastKnownLoginStatus";
NSString *const WSDefaults_LastReadings = @"WSDefaults_LastReadings";
NSString *const WSDefaults_DexcomToken = @"WSDefaults_DexcomToken";

//#define kTestReadings(epochMilliseconds) @[@{ \
//                                            @"timestamp": @((epochMilliseconds)), \
//                                            @"trend": @(5),\
//                                            @"value": @(102), \
//                                        },]

@implementation DefaultsController

+ (void)addLogMessage:(NSString *)logMessage
{
    static NSDateFormatter *_logDateFormatter = nil;
    if (!_logDateFormatter) {
        _logDateFormatter = [[NSDateFormatter alloc] init];
        _logDateFormatter.dateStyle = NSDateFormatterShortStyle;
        _logDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    NSArray *logMessagesArray = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LogMessageArray];
    if (!logMessagesArray) {
        logMessagesArray = @[];
    }
    
    NSString * fullEntry = [NSString stringWithFormat:@"%@ - %@", [_logDateFormatter stringFromDate:[NSDate date]], logMessage];
    
    NSMutableArray *mutableLogMessagesArray = [logMessagesArray mutableCopy];
    [mutableLogMessagesArray addObject:fullEntry];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutableLogMessagesArray forKey:WSDefaults_LogMessageArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray <NSString *> *)allLogMessages
{
    NSArray <NSString *> *logMessagesArray = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LogMessageArray];
    if (!logMessagesArray) {
        logMessagesArray = @[];
    }
    
    return logMessagesArray;
}

+ (void)clearAllLogMessages
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LogMessageArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (WSLoginStatus)lastKnownLoginStatus
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:WSDefaults_LastKnownLoginStatus];
}

+ (void)setLastKnownLoginStatus:(WSLoginStatus)status
{
    [[NSUserDefaults standardUserDefaults] setInteger:status forKey:WSDefaults_LastKnownLoginStatus];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray <NSDictionary *> *)latestBloodSugarReadings
{
#ifndef kTestReadings
    NSArray *lastReadings = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings];
#else
    NSDate *date = [NSDate date];
    NSTimeInterval epoch = [date timeIntervalSince1970] - (60.0f * 61.0f);
    epoch *= 1000.0f;
    NSArray *lastReadings = kTestReadings(epoch);
#endif
    
    return lastReadings;
}

+ (NSString *)dexcomToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_DexcomToken];
}

+ (void)setDexcomToken:(NSString *)dexcomToken
{
    if (!dexcomToken) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_DexcomToken];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:dexcomToken forKey:WSDefaults_DexcomToken];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
