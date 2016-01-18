//
//  WebRequestController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/12/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const WSDefaults_LastReadings;

@class WebRequestController;
@class AuthenticationController;

@protocol WebRequestControllerDelegate <NSObject>

- (void)webRequestControllerDidFetchNewBloodSugarData:(WebRequestController *)webRequestController;

@end

@interface WebRequestController : NSObject

@property (nonatomic, weak) id<WebRequestControllerDelegate> delegate;

@property (nonatomic, strong) AuthenticationController *authenticationController;

@property (nonatomic, strong) NSString *dexcomToken;
@property (nonatomic, strong) NSDictionary * latestBloodSugarData;

@property (nonatomic, strong) NSDate *lastFetchAttempt;

- (void)performFetch;
- (void)performFetchAndWait;

@end
