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

NSString *const WSNotificationBloodSugarDataChanged = @"WSNotificationBloodSugarDataChanged";

@interface ExtensionDelegate () <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        NSLog(@"activate session called on watch");
    }
}

- (void)applicationDidBecomeActive {
    if ([[WCSession defaultSession] isReachable]) {
        [[WCSession defaultSession] sendMessage:@{@"watchIsRequestingUpdate": @(YES)} replyHandler:NULL errorHandler:NULL];
    }
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

#pragma mark - WCSessionDelegate methods

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *, id> *)userInfo
{
    NSLog(@"watch received data: '%@'", userInfo);
    
    if (userInfo) {
        self.bloodSugarValues = userInfo[@"readings"];
    }
    
    for (CLKComplication *complication in [[CLKComplicationServer sharedInstance] activeComplications]) {
        [[CLKComplicationServer sharedInstance] reloadTimelineForComplication:complication];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationBloodSugarDataChanged object:nil];
}

//- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *, id> *)applicationContext
//{
//    NSLog(@"watch received data: '%@'", applicationContext);
//    
//    if (applicationContext) {
//        self.bloodSugarValues = applicationContext[@"readings"];
//    }
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationBloodSugarDataChanged object:nil];
//}

@end
