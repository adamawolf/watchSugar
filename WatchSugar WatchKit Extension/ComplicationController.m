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
    
    NSString *bloodSugarValue = @"-";
    if (extensionDelegate.bloodSugarValues.count) {
        NSDictionary *mostRecent = extensionDelegate.bloodSugarValues[0];
        
        int mostRecentValue = [mostRecent[@"value"] intValue];
        bloodSugarValue = [NSString stringWithFormat:@"%d", mostRecentValue];
    }
    
    
    CLKComplicationTimelineEntry* entry = nil;
    NSDate* now = [NSDate date];
    
    // Create the template and timeline entry.
    if (complication.family == CLKComplicationFamilyModularSmall) {
        CLKComplicationTemplateModularSmallSimpleText *textTemplate = [[CLKComplicationTemplateModularSmallSimpleText alloc] init];
        textTemplate.textProvider = [CLKSimpleTextProvider textProviderWithText:[NSString stringWithFormat:@"%@ mg/dL", bloodSugarValue] shortText:bloodSugarValue];
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:textTemplate];
    } else if (complication.family == CLKComplicationFamilyCircularSmall) {
        CLKComplicationTemplateCircularSmallSimpleText *textTemplate = [[CLKComplicationTemplateCircularSmallSimpleText alloc] init];
        textTemplate.textProvider = [CLKSimpleTextProvider textProviderWithText:[NSString stringWithFormat:@"%@ mg/dL", bloodSugarValue] shortText:bloodSugarValue];
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:textTemplate];
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
        template = [[CLKComplicationTemplateModularSmallSimpleText alloc] init];
        ((CLKComplicationTemplateModularSmallSimpleText *)template).textProvider = [CLKSimpleTextProvider textProviderWithText:@"-- mg/dL" shortText:@"--"];
    } else if (complication.family == CLKComplicationFamilyCircularSmall) {
        template = [[CLKComplicationTemplateCircularSmallSimpleText alloc] init];
        ((CLKComplicationTemplateCircularSmallSimpleText *)template).textProvider = [CLKSimpleTextProvider textProviderWithText:@"-- mg/dL" shortText:@"--"];
    }
    
    handler(template);
}

@end
