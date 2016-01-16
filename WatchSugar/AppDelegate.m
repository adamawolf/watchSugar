//
//  AppDelegate.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "AppDelegate.h"
#import <WatchConnectivity/WatchConnectivity.h>

@interface AppDelegate () <WCSessionDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //initialize CocoaLumberjack
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    //initialize WatchConnectivity
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        
        DDLogDebug(@"activate session called on device");
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{

}

#pragma mark - WCSessionDelegate methods

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message
{

}

@end
