//
//  DefaultsLogController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/13/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "DefaultsController.h"
#include <stdlib.h>

NSString *const WSDefaults_LogMessageArray = @"WSDefaults_LogMessageArray";
NSString *const WSDefaults_LastKnownLoginStatus = @"WSDefaults_LastKnownLoginStatus";
NSString *const WSDefaults_LastReadings = @"WSDefaults_LastReadings";
NSString *const WSDefaults_TimeTravelEnabled = @"WSDefaults_TimeTravelEnabled";

NSString *const WSDefaults_UserGroup = @"WSDefaults_UserGroup";

NSString *const WSDefaults_WakeUpDeltaMetricsArray = @"WSDefaults_WakeUpDeltaMetricsArray";
NSString *const WSDefaults_ProcessingTimeMetricsArray = @"WSDefaults_ProcessingTimeMetricsArray";

NSString *const WSDefaults_LastNextRequestedUpdateDate = @"WSDefaults_LastNextRequestedUpdateDate";
NSString *const WSDefaults_LastUpdateStartDate = @"WSDefaults_LastUpdateStartDate";

NSString *const WSDefaults_LastUpdateDidChangeComplication = @"WSDefaults_LastUpdateDidChangeComplication";

NSString *const WSDefaults_MostRecentForegroundComplicationUpdate = @"WSDefaults_MostRecentForegroundComplicationUpdate";

static const NSTimeInterval kMaximumFreshnessInterval = 60.0f * 60.0f;
static const NSInteger kMaxBloodSugarReadings = 3 * 12;
static const NSTimeInterval kMaximumReadingHistoryInterval = 12 * 60.0f * 60.0f;

//#define kTestReadings(epochMilliseconds) @[@{ \
//                                            @"timestamp": @((epochMilliseconds)), \
//                                            @"trend": @(5),\
//                                            @"value": @(102), \
//                                        },]

@implementation DefaultsController

+ (void)configureInitialOptions
{
    WSUserGroup userGroup = [DefaultsController userGroup];
    
    if (userGroup == WSUserGroupNone) {
        //initially assign a user group and set corresponding settings
        if ([DefaultsController latestBloodSugarReadings].count > 3) {
            //user has already been testing a previous version
            [[NSUserDefaults standardUserDefaults] setInteger:WSUserGroupFirstWaveBetaTesters forKey:WSDefaults_UserGroup];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WSDefaults_TimeTravelEnabled];
#ifndef DEBUG
            //clear all logging from version 6
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LogMessageArray];
#endif
        } else {
            WSUserGroup randomUserGroup = arc4random_uniform(2) == 0 ? WSUserGroupSecondWaveBetaTesters_NoTimeTravel : WSUserGroupSecondWaveBetaTesters_WithTimeTravel;
            [[NSUserDefaults standardUserDefaults] setInteger:randomUserGroup forKey:WSDefaults_UserGroup];
            [[NSUserDefaults standardUserDefaults] setBool:randomUserGroup == WSUserGroupSecondWaveBetaTesters_WithTimeTravel forKey:WSDefaults_TimeTravelEnabled];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (WSUserGroup)userGroup
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:WSDefaults_UserGroup];
}

+ (void)addLogMessage:(NSString *)logMessage
{
#ifndef DEBUG
    return; //don't log in user defaults outside of DEBUG builds
#endif
    
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
    
    NSString *fullEntry = [NSString stringWithFormat:@"%@ - %@", [_logDateFormatter stringFromDate:[NSDate date]], logMessage];
    
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
    
    return lastReadings ? lastReadings : @[];
}

+ (WSProcessReadingResult)processNewBloodSugarData:(NSDictionary *)prospectiveNewBloodSugarData
{
    NSDictionary *(^createReadingFromDataDictionary)(NSDictionary *, NSTimeInterval) = ^(NSDictionary *dataDictionary, NSTimeInterval timestampMilliseconds) {
        if (dataDictionary) {
            return @{
                     @"timestamp": @(timestampMilliseconds),
                     @"trend": dataDictionary[@"Trend"],
                     @"value": dataDictionary[@"Value"],
                     };
        } else {
            return @{
                     @"timestamp": @(timestampMilliseconds),
                     @"isNoValueReading": @(YES),
                     };
        }
    };
    
    NSArray <NSDictionary *> *currentReadings = [DefaultsController latestBloodSugarReadings];
    NSDictionary *latestReading = [currentReadings lastObject];
    
    NSMutableArray <NSDictionary *> *newReadingsToAdd = [NSMutableArray new];
    
    //check the cases in which we want to add a new entry
    
    //1) there is newBloodSugar data, meaning: there is PROSPECTIVE new blood sugar data AND its timestamp is different than latestReading's
    __block BOOL newBloodSugarData = NO;
    if (prospectiveNewBloodSugarData) {
        NSString *newBloodSugarDataTimestampAsString = [prospectiveNewBloodSugarData[@"WT"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]][1];
        NSTimeInterval newBloodSugarTimeStamp = [newBloodSugarDataTimestampAsString longLongValue];
        
        //assume new, scan array backwards looking for anything reading with matching timestamp. if so, not new
        newBloodSugarData = YES;
        [currentReadings enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *currentReading, NSUInteger idx, BOOL *stop) {
            if ([currentReading[@"timestamp"] longLongValue] == newBloodSugarTimeStamp) {
                newBloodSugarData = NO;
                *stop = YES;
            }
        }];
        
        if (newBloodSugarData) {
            [newReadingsToAdd addObject:createReadingFromDataDictionary(prospectiveNewBloodSugarData, newBloodSugarTimeStamp)];
        }
    }
    
    //2) there is not new bloodSugarData AND the latestReading's timestamp is older than the freshness interval
    BOOL noNewBloodSugarDataAndLatestIsNotFresh = NO;
    if (!newBloodSugarData) {
        NSTimeInterval latestReadingTimestamp = [latestReading[@"timestamp"] longLongValue] / 1000.0f;
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        
        while (currentTimestamp - latestReadingTimestamp > kMaximumFreshnessInterval) {
            noNewBloodSugarDataAndLatestIsNotFresh = YES;
            
            latestReadingTimestamp = latestReadingTimestamp + kMaximumFreshnessInterval;
            [newReadingsToAdd addObject:createReadingFromDataDictionary(nil, latestReadingTimestamp * 1000.0f)];
        }
    }
    
    WSProcessReadingResult result = WSProcessReadingResultNothingChanged;
    
    //perform the addition if appropriate
    if (newBloodSugarData || noNewBloodSugarDataAndLatestIsNotFresh) {
        NSMutableArray *mutableReadings = [currentReadings mutableCopy];
        [mutableReadings addObjectsFromArray:newReadingsToAdd];
        
        //filter the readings according to some additional parameters
        //prohibit too many readings
        while ([mutableReadings count] > kMaxBloodSugarReadings) {
            [mutableReadings removeObjectAtIndex:0];
        }
        
        //prohibit readings from more than kMaximumReadingHistoryInterval ago
        NSTimeInterval oldestAllowableTimeInterval = [[NSDate date] timeIntervalSince1970] - kMaximumReadingHistoryInterval;
        while ([mutableReadings firstObject] && [[mutableReadings firstObject][@"timestamp"] doubleValue] / 1000.00 < oldestAllowableTimeInterval) {
            [mutableReadings removeObjectAtIndex:0];
        }
        
        //save
        [[NSUserDefaults standardUserDefaults] setObject:mutableReadings forKey:WSDefaults_LastReadings];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //report result
        result = WSProcessReadingResultNewResultAdded;
    }
    
    return result;
}

+ (BOOL)timeTravelEnabled;
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WSDefaults_TimeTravelEnabled];
}

+ (void)setTimeTravelEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:WSDefaults_TimeTravelEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Metrics methods

+ (NSDate *)lastNextRequestedUpdateDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_LastNextRequestedUpdateDate];
}

+ (void)setLastNextRequestedUpdateDate:(NSDate *)date
{
    if (date) {
        [[NSUserDefaults standardUserDefaults] setObject:date forKey:WSDefaults_LastNextRequestedUpdateDate];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LastNextRequestedUpdateDate];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDate *)lastUpdateStartDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_LastUpdateStartDate];
}

+ (void)setLastUpdateStartDate:(NSDate *)date
{
    if (date) {
        [[NSUserDefaults standardUserDefaults] setObject:date forKey:WSDefaults_LastUpdateStartDate];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LastUpdateStartDate];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)lastUpdateDidChangeComplication
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WSDefaults_LastUpdateDidChangeComplication];
}

+ (void)setLastUpdateDidChangeComplication:(BOOL)didChange
{
    [[NSUserDefaults standardUserDefaults] setBool:didChange forKey:WSDefaults_LastUpdateDidChangeComplication];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray <NSDictionary *> *)wakeUpDeltaMetricEntries
{
    NSArray *entries = [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_WakeUpDeltaMetricsArray];
    
    return entries ? entries : @[];
}

+ (void)appendWakeUpDeltaMetricEntry:(NSDictionary *)entry
{
    if (!entry || !entry[@"date"] || !entry[@"deltaMinutes"]) {
        return;
    }
    
    NSArray *entries = [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_WakeUpDeltaMetricsArray];
    
    if (!entries) {
        entries = @[];
    }
    
    NSMutableArray *mutableEntries = [entries mutableCopy];
    [mutableEntries addObject:entry];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutableEntries forKey:WSDefaults_WakeUpDeltaMetricsArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearWakeUpDeltaMetricEntries
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_WakeUpDeltaMetricsArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray <NSDictionary *> *)processingTimeMetricEntries
{
    NSArray *entries = [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_ProcessingTimeMetricsArray];
    
    return entries ? entries : @[];
}

+ (void)appendProcessingTimeMetricsArray:(NSDictionary *)entry
{
    if (!entry || !entry[@"date"] || !entry[@"deltaSeconds"] || !entry[@"didChangeData"]) {
        return;
    }
    
    NSArray *entries = [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_ProcessingTimeMetricsArray];
    
    if (!entries) {
        entries = @[];
    }
    
    NSMutableArray *mutableEntries = [entries mutableCopy];
    [mutableEntries addObject:entry];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutableEntries forKey:WSDefaults_ProcessingTimeMetricsArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearProcessingTimeMetricsArray
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_ProcessingTimeMetricsArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDate *)mostRecentForegroundComplicationUpdate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_MostRecentForegroundComplicationUpdate];
}

+ (void)setMostRecentForegroundComplicationUpdate:(NSDate *)date
{
    if (date) {
        [[NSUserDefaults standardUserDefaults] setObject:date forKey:WSDefaults_MostRecentForegroundComplicationUpdate];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_MostRecentForegroundComplicationUpdate];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
