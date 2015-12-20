//
//  InterfaceController.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "InterfaceController.h"

#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController() <WCSessionDelegate>

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    NSLog(@"watch awakeWithContext");
    // Configure interface objects here.
}

- (void)willActivate {
    [super willActivate];
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#pragma mark - WCSessionDelegate methods

- (void)sessionReachabilityDidChange:(WCSession *)session
{
    NSLog(@"sessionReachabilityDidChange: %@", session);
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message
{
    NSLog(@"watch received data: %@", message);
}

@end



