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

#import "WebRequestController.h"
#import "AuthenticationController.h"

@interface ExtensionDelegate () <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching
{
    [DefaultsController addLogMessage:@"applicationDidFinishLaunching"];
    
    self.authenticationController = [[AuthenticationController alloc] init];
    
    if (!self.webRequestController) {
        self.webRequestController = [[WebRequestController alloc] init];
        
        [DefaultsController addLogMessage:[NSString stringWithFormat:@"ExtensionDelegate allocated: %@", self.webRequestController]];
    }
    
    //initialize WatchConnectivity
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        
        NSLog(@"activate session called on watch");
    }
    
    NSString *logMessage = [NSString stringWithFormat:@"last know login status on device: %u", [DefaultsController lastKnownLoginStatus]];
    NSLog(@"%@", logMessage);
    [DefaultsController addLogMessage:logMessage];
}

- (void)applicationDidBecomeActive
{
    if ([DefaultsController lastKnownLoginStatus] == WSLoginStatus_None && [WCSession defaultSession].isReachable) {
        [self requestAuthenticationPayloadFromDevice];
    }
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

#pragma mark - Helper methods

- (void)requestAuthenticationPayloadFromDevice
{
    NSLog(@"requestAuthenticationPayloadFromDevice");
    
    [[WCSession defaultSession] sendMessage:@{@"watchIsRequestingAuthenticationPayload": @YES} replyHandler:NULL errorHandler:^(NSError *error) {
        NSLog(@"WCSession error when requesting updated authentication payload: %@", error);
    }];
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
}

@end
