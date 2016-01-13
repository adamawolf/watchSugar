//
//  WebRequestController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/12/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "WebRequestController.h"

#import <AFNetworking/AFNetworking.h>

NSString *const WSNotificationDexcomDataChanged = @"WSNotificationDexcomDataChanged";
NSString *const WSDefaults_LastReadings = @"WSDefaults_LastReadings";

@interface WebRequestController ()

@end

@implementation WebRequestController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fetchSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)performFetchInBackground:(BOOL)inBackground
{
    self.lastFetchAttempt = [NSDate date];
    
    if (!self.dexcomToken) {
        [self authenticateWithDexcomInBackground:inBackground];
    } else {
        if (!self.subscriptionId) {
            [self fetchSubscriptionsInBackground:inBackground];
        } else {
            [self fetchLatestBloodSugarInBackground:inBackground];
        }
    }
}

+ (void)dexcomPOSTToURLString:(NSString *)URLString
               withParameters:(id)parameters
             withSuccessBlock:(void (^)(NSURLSessionDataTask *, id))success
             withFailureBlock:(void (^)(NSURLSessionDataTask *, NSError *))failure
                 inBackground:(BOOL)inBackground
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    if (inBackground) {
        manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    }
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];
    [manager setRequestSerializer:requestSerializer];
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager setResponseSerializer:responseSerializer];
    
    [manager POST:URLString parameters:parameters progress:NULL success:success failure:failure];
}

- (void)authenticateWithDexcomInBackground:(BOOL)inBackground
{
    NSString *URLString = @"https://share1.dexcom.com/ShareWebServices/Services/General/LoginSubscriberAccount";
    NSDictionary *parameters = @{@"accountId": @"***REMOVED***",
                                 @"password": @"A***REMOVED***",
                                 @"applicationId": @"d89443d2-327c-4a6f-89e5-496bbb0317db"};
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:parameters
                               withSuccessBlock:^(NSURLSessionDataTask * task, id responseObject) {
                                   if (!inBackground) {
                                       NSLog(@"received dexcom token: %@", responseObject);
                                   }
                                   self.dexcomToken = responseObject;
                                   
                                   if (!inBackground) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationDexcomDataChanged object:nil userInfo:nil];
                                   }
                                   
                                   if (!self.subscriptionId) {
                                       [self fetchSubscriptionsInBackground:inBackground];
                                   }
                               }
                               withFailureBlock:^(NSURLSessionDataTask * task, NSError * error) {
                                   if (!inBackground) {
                                       NSLog(@"error: %@", error);
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                                   inBackground:inBackground];
}

- (void)fetchSubscriptionsInBackground:(BOOL)inBackground
{
    NSString *URLString = [NSString stringWithFormat:@"https://share1.dexcom.com/ShareWebServices/Services/Subscriber/ListSubscriberAccountSubscriptions?sessionId=%@", self.dexcomToken];
    NSString *parameters = nil;
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:parameters
                               withSuccessBlock:^(NSURLSessionDataTask * task, id responseObject) {
                                   if (!inBackground) {
                                       NSLog(@"received subscription list: %@", responseObject);
                                   }
                                   self.subscriptionId = responseObject[0][@"SubscriptionId"];
                                   
                                   if (!inBackground) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationDexcomDataChanged object:nil userInfo:nil];
                                   }
                                   
                                   if (!self.latestBloodSugarData) {
                                       [self fetchLatestBloodSugarInBackground:inBackground];
                                   }
                               }
                               withFailureBlock:^(NSURLSessionDataTask * task, NSError * error) {
                                   if (!inBackground) {
                                       NSLog(@"error: %@", error);
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                                   inBackground:inBackground];
}

- (void)fetchLatestBloodSugarInBackground:(BOOL)inBackground
{
    NSString *URLString = [NSString stringWithFormat:@"https://share1.dexcom.com/ShareWebServices/Services/Subscriber/ReadLastGlucoseFromSubscriptions?sessionId=%@", self.dexcomToken];
    NSArray *parameters = @[self.subscriptionId];
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:parameters
                               withSuccessBlock:^(NSURLSessionDataTask * task, id responseObject) {
                                   NSLog(@"received blood sugar data: %@", responseObject);
                                   [self setLatestBloodSugarData:responseObject[0][@"Egv"] inBackground:inBackground];
                               }
                               withFailureBlock:^(NSURLSessionDataTask * task, NSError * error) {
                                   NSDictionary *jsonError = [NSJSONSerialization JSONObjectWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:0 error:NULL];
                                   if (!inBackground) {
                                       NSLog(@"error: %@", error);
                                       NSLog(@"error response: %@", jsonError);
                                   }
                                   
                                   if ([jsonError[@"Code"] isEqualToString:@"SessionNotValid"]) {
                                       self.dexcomToken = nil;
                                       self.subscriptionId = nil;
                                       self.latestBloodSugarData = nil;
                                       
                                       [self performFetchInBackground:inBackground];
                                   } else {
                                       if (inBackground) {
                                           //failure
                                           dispatch_semaphore_signal(self.fetchSemaphore);
                                       }
                                   }
                               }
                                   inBackground:inBackground];
}

-(void)setLatestBloodSugarData:(NSDictionary *)latestBloodSugarData
{
    [self setLatestBloodSugarData:latestBloodSugarData inBackground:NO];
}

static const NSInteger kMaxReadings = 20;

-(void)setLatestBloodSugarData:(NSDictionary *)latestBloodSugarData inBackground:(BOOL)inBackground
{
    _latestBloodSugarData = latestBloodSugarData;
    
    if (_latestBloodSugarData) {
        
        NSArray *lastReadings = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings];
        NSDictionary *latestReading = [lastReadings lastObject];
        
        NSString *STDate = [_latestBloodSugarData[@"ST"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]][1];
        int64_t epochMilliseconds = [STDate longLongValue];
        if ([latestReading[@"timestamp"] longLongValue] != epochMilliseconds)
        {
            NSDictionary *newReading = @{
                                         @"timestamp": @(epochMilliseconds),
                                         @"trend": _latestBloodSugarData[@"Trend"],
                                         @"value": _latestBloodSugarData[@"Value"],
                                         };
            
            NSMutableArray *mutableLastReadings = [lastReadings mutableCopy];
            [mutableLastReadings addObject:newReading];
            
            while ([mutableLastReadings count] > kMaxReadings) {
                [mutableLastReadings removeObjectAtIndex:0];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:mutableLastReadings forKey:WSDefaults_LastReadings];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            if (!inBackground) {
                NSLog(@"Latest Egv value has already been saved to Core Data. Skipping.");
            }
        }
        
        if (!inBackground) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationDexcomDataChanged object:nil userInfo:nil];
        }
    }
    
    if (inBackground) {
        //success
        dispatch_semaphore_signal(self.fetchSemaphore);
    }
}

@end
