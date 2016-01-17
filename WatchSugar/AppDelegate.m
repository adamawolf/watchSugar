//
//  AppDelegate.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "AppDelegate.h"
#import <WatchConnectivity/WatchConnectivity.h>

#import "ViewController.h"

#import "AuthenticationController.h"
#import "WebRequestController.h"

@interface AppDelegate () <WCSessionDelegate>

@property (nonatomic, strong) AuthenticationController *authenticationController;
@property (nonatomic, strong) WebRequestController *webRequestController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.authenticationController = [[AuthenticationController alloc] init];
    self.webRequestController = [[WebRequestController alloc] init];
    
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
    
    ViewController *rootInterfaceController = (ViewController *)self.window.rootViewController;
    rootInterfaceController.authenticationController = self.authenticationController;
    rootInterfaceController.webRequestController = self.webRequestController;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{

}

#pragma mark - Helper methods

- (void)updateApplicationContext
{
    NSMutableDictionary *context = [NSMutableDictionary new];
    context[@"loginStatus"] = @(self.authenticationController.loginStatus);
    
    NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
    if (authenticationPayload) {
        context[@"authenticationPayload"] = authenticationPayload;
    }
    
    NSError *anError;
    [[WCSession defaultSession] updateApplicationContext:context error:&anError];
    
    if (anError) {
        DDLogDebug(@"error updateApplicationContext: %@", anError);
    }
}

#pragma mark - WCSessionDelegate methods

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message
{
    if ([message[@"watchIsRequestingAuthenticationPayload"] boolValue]) {
        [self updateApplicationContext];
    }
}

@end
