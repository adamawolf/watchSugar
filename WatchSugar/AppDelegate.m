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

@interface AppDelegate () <WCSessionDelegate>

@property (nonatomic, strong) AuthenticationController *authenticationController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.authenticationController = [[AuthenticationController alloc] init];
    
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
