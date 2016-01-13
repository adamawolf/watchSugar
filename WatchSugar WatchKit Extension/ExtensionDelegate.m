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

@interface ExtensionDelegate () <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    
    if (!self.webRequestController) {
        self.webRequestController = [[WebRequestController alloc] init];
    }
}

- (void)applicationDidBecomeActive {

}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

@end
