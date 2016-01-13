//
//  ComplicationController.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "ComplicationController.h"

#import "ExtensionDelegate.h"

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

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    // Get the current complication data from the extension delegate.    
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    WebRequestController *webRequestController = extensionDelegate.webRequestController;
    
    [webRequestController performFetchInBackground:YES];
    dispatch_semaphore_wait(webRequestController.fetchSemaphore, DISPATCH_TIME_FOREVER);
    
    //...
    
    NSString *bloodSugarValue = @"-";
    UIImage *trendImage = nil;
    
    NSArray *lastReadings = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings];
    if (lastReadings.count) {
        NSDictionary *latestReading = [lastReadings lastObject];
        
        int mostRecentValue = [latestReading[@"value"] intValue];
        bloodSugarValue = [NSString stringWithFormat:@"%d", mostRecentValue];
        
        int trend = [latestReading[@"trend"] intValue];
        NSString *trendImageName = [NSString stringWithFormat:@"trend_%d", trend];
        trendImage = [UIImage imageNamed:trendImageName];
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

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries prior to the given date
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after to the given date
    handler(nil);
}

#pragma mark Update Scheduling

- (void)getNextRequestedUpdateDateWithHandler:(void(^)(NSDate * __nullable updateDate))handler {
    NSDate *futureDate = [[NSDate date] dateByAddingTimeInterval:60.0f * 9.5];
    handler(futureDate);
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
