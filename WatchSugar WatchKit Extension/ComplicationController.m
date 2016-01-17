//
//  ComplicationController.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "ComplicationController.h"

#import "ExtensionDelegate.h"

#import "DefaultsController.h"

#import "WebRequestController.h"

@interface ComplicationController ()

@end

@implementation ComplicationController

#pragma mark - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
    handler(CLKComplicationTimeTravelDirectionNone);
}

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler
{
    NSString *bloodSugarValue = @"-";
    UIImage *trendImage = nil;
    NSString *timeStampAsDate = nil;
    
    NSArray *lastReadings = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings];
    if (lastReadings.count) {
        NSDictionary *latestReading = [lastReadings lastObject];
        
        int mostRecentValue = [latestReading[@"value"] intValue];
        bloodSugarValue = [NSString stringWithFormat:@"%d", mostRecentValue];
        
        int trend = [latestReading[@"trend"] intValue];
        NSString *trendImageName = [NSString stringWithFormat:@"trend_%d", trend];
        trendImage = [UIImage imageNamed:trendImageName];
        
        NSTimeInterval epoch = [latestReading[@"timestamp"] doubleValue] / 1000.00; //dexcom dates include milliseconds
        NSDate *timeStampDate = [NSDate dateWithTimeIntervalSince1970:epoch];
        
        static NSDateFormatter *_timeStampDateFormatter = nil;
        if (!_timeStampDateFormatter) {
            _timeStampDateFormatter = [[NSDateFormatter alloc] init];
            _timeStampDateFormatter.dateStyle = NSDateFormatterShortStyle;
            _timeStampDateFormatter.timeStyle = NSDateFormatterShortStyle;
        }
        timeStampAsDate = [_timeStampDateFormatter stringFromDate:timeStampDate];
        
        [DefaultsController addLogMessage:[NSString stringWithFormat:@"getCurrentTimelineEntryForComplication returning BS of %@, reading date %@", bloodSugarValue, timeStampAsDate]];
    } else {
        [DefaultsController addLogMessage:[NSString stringWithFormat:@"getCurrentTimelineEntryForComplication returning %@", bloodSugarValue]];
    }
    
    // Create the template and timeline entry.
    CLKComplicationTimelineEntry* entry = nil;
    NSDate* now = [NSDate date];
    if (complication.family == CLKComplicationFamilyModularSmall) {
        CLKComplicationTemplateModularSmallStackImage *smallStackImageTemplate = [[CLKComplicationTemplateModularSmallStackImage alloc] init];
        smallStackImageTemplate.line1ImageProvider = [CLKImageProvider imageProviderWithOnePieceImage:trendImage];
        smallStackImageTemplate.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:[NSString stringWithFormat:@"%@ mg/dL", bloodSugarValue] shortText:bloodSugarValue];

        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:smallStackImageTemplate];
    } else if (complication.family == CLKComplicationFamilyCircularSmall) {
        CLKComplicationTemplateCircularSmallStackImage *smallStackImageTemplate = [[CLKComplicationTemplateCircularSmallStackImage alloc] init];
        smallStackImageTemplate.line1ImageProvider = [CLKImageProvider imageProviderWithOnePieceImage:trendImage];
        smallStackImageTemplate.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:[NSString stringWithFormat:@"%@ mg/dL", bloodSugarValue] shortText:bloodSugarValue];
        
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:smallStackImageTemplate];
    }
    else {
        // ...configure entries for other complication families.
    }
    
    // Pass the timeline entry back to ClockKit.
    handler(entry);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler
{
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after to the given date
    handler(nil);
}

#pragma mark Update Scheduling

- (void)getNextRequestedUpdateDateWithHandler:(void(^)(NSDate * __nullable updateDate))handler
{
    NSDate *futureDate = [[NSDate date] dateByAddingTimeInterval:60.0f * 9.5];
    
    static NSDateFormatter *_timeStampDateFormatter = nil;
    if (!_timeStampDateFormatter) {
        _timeStampDateFormatter = [[NSDateFormatter alloc] init];
        _timeStampDateFormatter.dateStyle = NSDateFormatterShortStyle;
        _timeStampDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    [DefaultsController addLogMessage:[NSString stringWithFormat:@"getNextRequestedUpdateDateWithHandler requesting future date: %@", [_timeStampDateFormatter stringFromDate:futureDate]]];
    
    handler(futureDate);
}

- (void)requestedUpdateDidBegin
{
    [DefaultsController addLogMessage:@"ComplicationController requestedUpdateDidBegin"];
    
    NSDictionary *previousLatestReading = [[[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings] lastObject];
    
    // Get the current complication data from the extension delegate.
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    if (!extensionDelegate.webRequestController) {
        extensionDelegate.webRequestController = [[WebRequestController alloc] init];
        
        [DefaultsController addLogMessage:[NSString stringWithFormat:@"requestedUpdateDidBegin allocated: %@", extensionDelegate.webRequestController]];
    }
    
    WebRequestController *webRequestController = extensionDelegate.webRequestController;
    
    if (!webRequestController.lastFetchAttempt || [[NSDate date] timeIntervalSinceDate:webRequestController.lastFetchAttempt] > 60.0f) {
        [webRequestController performFetchAndWait];
    }
    
    BOOL didChange = NO;
    
    NSDictionary *latestReading = [[[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings] lastObject];
    
    if (!previousLatestReading && latestReading) {
        didChange = YES;
    } else if (previousLatestReading && latestReading) {
        NSTimeInterval previousEpoch = [previousLatestReading[@"timestamp"] doubleValue] / 1000.00;
        NSTimeInterval latestEpoch = [latestReading[@"timestamp"] doubleValue] / 1000.00;
        
        didChange = previousEpoch != latestEpoch;
    }
    
    if (didChange) {
        for (CLKComplication *complication in [[CLKComplicationServer sharedInstance] activeComplications]) {
            [[CLKComplicationServer sharedInstance] reloadTimelineForComplication:complication];
        }
    }
}

- (void)requestedUpdateBudgetExhausted
{
    [DefaultsController addLogMessage:@"ComplicationController requestedUpdateBudgetExhausted!"];
}

#pragma mark - Placeholder Templates

- (void)getPlaceholderTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached
    
    CLKComplicationTemplate* template = nil;
    
    // Create the template and timeline entry.
    if (complication.family == CLKComplicationFamilyModularSmall) {
        CLKComplicationTemplateModularSmallStackImage *smallStackImageTemplate = [[CLKComplicationTemplateModularSmallStackImage alloc] init];
        smallStackImageTemplate.line1ImageProvider = [CLKImageProvider imageProviderWithOnePieceImage:[UIImage imageNamed:@"trend_4"]];
        smallStackImageTemplate.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:@"-- mg/dL" shortText:@"--"];
        
        template = smallStackImageTemplate;
    } else if (complication.family == CLKComplicationFamilyCircularSmall) {
        CLKComplicationTemplateCircularSmallStackImage *smallStackImageTemplate = [[CLKComplicationTemplateCircularSmallStackImage alloc] init];
        smallStackImageTemplate.line1ImageProvider = [CLKImageProvider imageProviderWithOnePieceImage:[UIImage imageNamed:@"trend_4"]];
        smallStackImageTemplate.line2TextProvider = [CLKSimpleTextProvider textProviderWithText:@"-- mg/dL" shortText:@"--"];
        
        template = smallStackImageTemplate;
    }
    
    handler(template);
}

@end
