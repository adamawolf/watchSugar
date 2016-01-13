//
//  ExtensionDelegate.h
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import "WebRequestController.h"

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>

@property (nonatomic, strong) WebRequestController *webRequestController;

@end
