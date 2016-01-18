//
//  ExtensionDelegate.h
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@class WebRequestController;
@class AuthenticationController;

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>

@property (nonatomic, strong) AuthenticationController * authenticationController;
@property (nonatomic, strong) WebRequestController *webRequestController;

- (void)initializeSubControllers;

@end
