//
//  WebRequestController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/12/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "WatchWebRequestController.h"
#import <ClockKit/ClockKit.h>

#import <AFNetworking/AFNetworking.h>

#import "DefaultsController.h"

static const NSInteger kMaxBloodSugarReadings = 6 * 12;
static const NSTimeInterval kMaximumReadingHistoryInterval = 12 * 60.0f * 60.0f;

@interface WatchWebRequestController ()

@property (nonatomic, strong) dispatch_semaphore_t fetchSemaphore;
@property (nonatomic, assign) BOOL isAttemptingReAuth;

@end

@implementation WatchWebRequestController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fetchSemaphore = dispatch_semaphore_create(0);
    }
    
    return self;
}

#pragma mark - Custom Setter and Getter methods

- (NSString *)dexcomToken
{
    return [DefaultsController dexcomToken];
}

- (void)setDexcomToken:(NSString *)dexcomToken
{
    [DefaultsController setDexcomToken:dexcomToken];
}

- (void)performFetch
{
    self.lastFetchAttempt = [NSDate date];
    self.isAttemptingReAuth = NO;
    
    [self performFetchInternal];
}

- (void)performFetchInternal
{
    [DefaultsController addLogMessage:@"performFetch"];
    
    NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
    if (!authenticationPayload[@"accountName"] || !authenticationPayload[@"password"]) {
        [DefaultsController addLogMessage:@"watch app not authenitcated, skipping fetch attempt"];
        return;
    }
    
    if (!self.dexcomToken) {
        NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
        [self authenticateWithDexcomAccountName:authenticationPayload[@"accountName"] andPassword:authenticationPayload[@"password"] shouldWait:NO];
    } else {
        [self fetchLatestBloodSugarAndWait:NO];
    }
}

- (void)performFetchAndWait
{
    [self performFetchAndWaitInternal];
    
    dispatch_semaphore_wait(self.fetchSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)performFetchAndWaitInternal
{
    self.lastFetchAttempt = [NSDate date];
    
    [DefaultsController addLogMessage:@"performFetchAndWait"];
    
    NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
    if (!authenticationPayload[@"accountName"] || !authenticationPayload[@"password"]) {
        [DefaultsController addLogMessage:@"watch app not authenitcated, skipping fetch attempt"];
        dispatch_semaphore_signal(self.fetchSemaphore);
        return;
    }
    
    if (!self.dexcomToken) {
        NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
        [self authenticateWithDexcomAccountName:authenticationPayload[@"accountName"] andPassword:authenticationPayload[@"password"] shouldWait:YES];
    } else {
        [self fetchLatestBloodSugarAndWait:YES];
    }
}

- (void)authenticateWithDexcomAccountName:(NSString *)accountName andPassword:(NSString *)password shouldWait:(BOOL)shouldWait
{
    NSString *URLString = @"https://share2.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName";
    NSDictionary *parameters = @{@"accountName": accountName,
                                 @"password": password,
                                 @"applicationId": WSDexcomApplicationId_G5PlatinumApp};
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:parameters
                               withSuccessBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                   if (!shouldWait) {
                                       NSLog(@"received dexcom token: %@", responseObject);
                                   }
                                   self.dexcomToken = responseObject;
                                   
                                   if (!self.latestBloodSugarData) {
                                       [self fetchLatestBloodSugarAndWait:shouldWait];
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                               withFailureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                   if (!shouldWait) {
                                       NSLog(@"error: %@", error);
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                                     shouldWait:shouldWait];
}

- (void)fetchLatestBloodSugarAndWait:(BOOL)shouldWait
{
    [DefaultsController addLogMessage:[NSString stringWithFormat:@"fetchLatestBloodSugarAndWait:%@", shouldWait ? @"YES" : @"NO"]];
    
    NSString *URLString = [NSString stringWithFormat:@"https://share2.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId=%@&minutes=1400&maxCount=1", self.dexcomToken];
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:nil
                               withSuccessBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                   if (!shouldWait) {
                                       NSLog(@"received blood sugar data: %@", responseObject);
                                   }
                                   [self setLatestBloodSugarData:[responseObject firstObject] ? [responseObject firstObject] : nil inBackground:shouldWait];
                               }
                               withFailureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                   NSDictionary *jsonError = [NSJSONSerialization JSONObjectWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:0 error:NULL];
                                   if (!shouldWait) {
                                       NSLog(@"error: %@", error);
                                       if (jsonError) {
                                           NSLog(@"error response: %@", jsonError);
                                       } else {
                                           NSString *errorString = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                                           NSLog(@"%@", errorString);
                                       }
                                   }
                                   
                                   if (!self.isAttemptingReAuth &&
                                       ([jsonError[@"Code"] isEqualToString:@"SessionNotValid"] ||
                                        [jsonError[@"Code"] isEqualToString:@"SessionIdNotFound"])
                                       ) {
                                       self.isAttemptingReAuth = YES;
                                       
                                       self.dexcomToken = nil;
                                       self.latestBloodSugarData = nil;
                                       
                                       if (shouldWait) {
                                           [self performFetchAndWaitInternal];
                                       } else {
                                           [self performFetchInternal];
                                       }
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                                   shouldWait:shouldWait];
}

- (void)setLatestBloodSugarData:(NSDictionary *)latestBloodSugarData inBackground:(BOOL)inBackground
{
    _latestBloodSugarData = latestBloodSugarData;
    
    void(^updateUI)() = ^() {
        for (CLKComplication *complication in [[CLKComplicationServer sharedInstance] activeComplications]) {
            [[CLKComplicationServer sharedInstance] reloadTimelineForComplication:complication];
        }
        
        if (!inBackground) {
            [self.delegate webRequestControllerDidFetchNewBloodSugarData:self];
        }
    };
    
    if (_latestBloodSugarData) {
        NSArray *lastReadings = [DefaultsController latestBloodSugarReadings];
        lastReadings = lastReadings ? lastReadings : @[];
        NSDictionary *latestReading = [lastReadings lastObject];
        
        NSString *STDate = [_latestBloodSugarData[@"ST"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]][1];
        int64_t epochMilliseconds = [STDate longLongValue];
        if (!latestReading || [latestReading[@"timestamp"] longLongValue] != epochMilliseconds) {
            NSDictionary *newReading = @{
                                         @"timestamp": @(epochMilliseconds),
                                         @"trend": _latestBloodSugarData[@"Trend"],
                                         @"value": _latestBloodSugarData[@"Value"],
                                         };
            
            NSMutableArray *mutableLastReadings = [lastReadings mutableCopy];
            [mutableLastReadings addObject:newReading];
            
            //prohibit too many readings
            while ([mutableLastReadings count] > kMaxBloodSugarReadings) {
                [mutableLastReadings removeObjectAtIndex:0];
            }
            
            //prohibit readings from more than kMaximumReadingHistoryInterval ago
            NSTimeInterval oldestAllowableTimeInterval = [[NSDate date] timeIntervalSince1970] - kMaximumReadingHistoryInterval;
            while ([mutableLastReadings firstObject] && [[mutableLastReadings firstObject][@"timestamp"] doubleValue] / 1000.00 < oldestAllowableTimeInterval) {
                [mutableLastReadings removeObjectAtIndex:0];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:mutableLastReadings forKey:WSDefaults_LastReadings];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [DefaultsController addLogMessage:[NSString stringWithFormat:@"Save COMPLETE setLatestBloodSugarData:%@ inBackground:%@, %u readings", latestBloodSugarData, inBackground ? @"YES" : @"NO", mutableLastReadings.count]];
            
            updateUI();
            
        } else {
            [DefaultsController addLogMessage:[NSString stringWithFormat:@"Save skipped setLatestBloodSugarData:%@ inBackground:%@", latestBloodSugarData, inBackground ? @"YES" : @"NO"]];
            
            if (!inBackground) {
                NSLog(@"Latest Egv value has already been saved to Core Data. Skipping.");
            }
        }
    } else {
        //going from having a recent reading to not, update display or complications
        updateUI();
    }
    
    if (inBackground) {
        dispatch_semaphore_signal(self.fetchSemaphore);
    }
}

@end
