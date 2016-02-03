//
//  ExtensionDelegate.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "ExtensionDelegate.h"
#import "InterfaceController.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import <ClockKit/ClockKit.h>

#import "DefaultsController.h"

#import "WatchWebRequestController.h"
#import "AuthenticationController.h"

#import <Parse/Parse.h>

static NSInteger kMinMetricsBatchSize = 1;

@interface ExtensionDelegate () <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)initializeSubControllers
{
    self.authenticationController = [[AuthenticationController alloc] init];
    if (!self.webRequestController) {
        self.webRequestController = [[WatchWebRequestController alloc] init];
        self.webRequestController.authenticationController = self.authenticationController;
    }
}

- (void)applicationDidFinishLaunching
{
    [self initializeSubControllers];
    
    [DefaultsController configureInitialOptions];
    
    [Parse setApplicationId:@"9GhyzvbfPCu2fKMIsyILB0w7vLYSo5vBiD3PuEp7"
                  clientKey:@"ho4JrXvywYYxO1q2QLA4IblYL03WajjObjCzElT0"];
    
    //initialize WatchConnectivity
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        
        NSLog(@"activate session called on watch");
    }
    
    NSString *logMessage = [NSString stringWithFormat:@"applicationDidFinishLaunching, last know login status on device: %u", [DefaultsController lastKnownLoginStatus]];
    NSLog(@"%@", logMessage);
    [DefaultsController addLogMessage:logMessage];
}

- (void)applicationDidBecomeActive
{
    //clear dates used for processing background update metrics, since app is no longer in background and foreground updating will forcibly adjust timing of things
    [DefaultsController setLastNextRequestedUpdateDate:nil];
    [DefaultsController setLastUpdateStartDate:nil];
    
    [ExtensionDelegate processBackgroundMetrics];
    
    if ([DefaultsController lastKnownLoginStatus] == WSLoginStatus_None && [WCSession defaultSession].isReachable) {
        [self requestAuthenticationPayloadFromDevice];
    }
}

#pragma mark - Helper methods

- (void)requestAuthenticationPayloadFromDevice
{
    NSLog(@"requestAuthenticationPayloadFromDevice");
    
    [[WCSession defaultSession] sendMessage:@{@"watchIsRequestingAuthenticationPayload": @YES} replyHandler:NULL errorHandler:^(NSError *error) {
        NSLog(@"WCSession error when requesting updated authentication payload: %@", error);
    }];
}

+ (void)processBackgroundMetrics
{
    WSUserGroup userGroup = [DefaultsController userGroup];
    NSString *metricsClassName = @"Metrics_FirstWave";
    if (userGroup == WSUserGroupSecondWaveBetaTesters_NoTimeTravel) {
        metricsClassName = @"Metrics_SecondNoTimeTravel";
    } else if (userGroup == WSUserGroupSecondWaveBetaTesters_WithTimeTravel) {
        metricsClassName = @"Metrics_SecondWithTimeTravel";
    }
    
    NSArray <NSDictionary *> *wakeUpMetrics = [DefaultsController wakeUpDeltaMetricEntries];
    NSArray <NSDictionary *> *processingTimeMetrics = [DefaultsController processingTimeMetricEntries];
    
    if (wakeUpMetrics.count > kMinMetricsBatchSize && processingTimeMetrics.count > kMinMetricsBatchSize) {
        NSDate *firstDate = [wakeUpMetrics firstObject][@"date"];
        NSDate *lastDate = [processingTimeMetrics lastObject][@"date"];
        NSTimeInterval metricSpan = [lastDate timeIntervalSinceDate:firstDate];
        
        __block NSTimeInterval totalWakeUpDelta = 0.0f;
        [wakeUpMetrics enumerateObjectsUsingBlock:^(NSDictionary *curEntry, NSUInteger idx, BOOL *stop) {
            totalWakeUpDelta += [curEntry[@"deltaMinutes"] doubleValue];
        }];
        NSTimeInterval averageWakeUpDelta = totalWakeUpDelta / wakeUpMetrics.count;
        
        __block NSTimeInterval totalProcessingTime = 0.0f;
        __block NSInteger totalDidChangeData = 0;
        [processingTimeMetrics enumerateObjectsUsingBlock:^(NSDictionary *curEntry, NSUInteger idx, BOOL *stop) {
            totalProcessingTime += [curEntry[@"deltaSeconds"] doubleValue];
            totalDidChangeData += [curEntry[@"didChangeData"] boolValue] ? 1 : 0;
        }];
        NSTimeInterval averageProcessingTime = totalProcessingTime / processingTimeMetrics.count;
        CGFloat dataChangePercent = (totalDidChangeData * 1.0f) / (processingTimeMetrics.count * 1.0f) * 100.0f;
        
        PFObject *metrics = [PFObject objectWithClassName:metricsClassName];
        metrics[@"averageWakeUpDeltaMinutes"] = @(averageWakeUpDelta);
        metrics[@"averageProcessingTimeSeconds"] = @(averageProcessingTime);

        metrics[@"timespanHours"] = @(metricSpan / (60.0f * 60.0f));
        
        metrics[@"dataChangedPercent"] = @(dataChangePercent);
        metrics[@"dataChangedCount"] = @(totalDidChangeData);
        
        metrics[@"processingEntryCount"] = @(processingTimeMetrics.count);
        metrics[@"wakeEntryCount"] = @(wakeUpMetrics.count);
        
        metrics[@"rawWakeUpMetrics"] = wakeUpMetrics;
        metrics[@"rawProcessingTimeMetrics"] = processingTimeMetrics;

        [metrics saveInBackground];
        
        [DefaultsController clearWakeUpDeltaMetricEntries];
        [DefaultsController clearProcessingTimeMetricsArray];
    }
}

#pragma mark - WCSessionDelegate methods

- (void)sessionReachabilityDidChange:(WCSession *)session
{
    if ([DefaultsController lastKnownLoginStatus] == WSLoginStatus_None && [WCSession defaultSession].isReachable) {
        [self requestAuthenticationPayloadFromDevice];
    }
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext
{
    [DefaultsController setLastKnownLoginStatus:[applicationContext[@"loginStatus"] intValue]];
    
    if ([applicationContext[@"loginStatus"] intValue] == WSLoginStatus_NotLoggedIn) {
        [self.authenticationController clearAuthenticationPayload];
    } else if ([applicationContext[@"loginStatus"] intValue] == WSLoginStatus_LoggedIn) {
        [self.authenticationController saveAuthenticationPayloadToKeychain:applicationContext[@"authenticationPayload"]];
    }
    
    NSString *logMessage = [NSString stringWithFormat:@"handled updated applicationContext from device: %u", [applicationContext[@"loginStatus"] intValue]];
    NSLog(@"%@", logMessage);
    [DefaultsController addLogMessage:logMessage];
    
    InterfaceController *interfaceController = (InterfaceController *)[WKExtension sharedExtension].rootInterfaceController;
    [interfaceController updateDisplay];
}

@end
