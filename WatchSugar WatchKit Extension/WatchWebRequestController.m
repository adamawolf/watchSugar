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

//when called from the UI (InterfaceController) requests happen in the background
//when called from the ComplicationController request happens inline on the same thread as requestedUpdateDidBegin
//  accomplish this by waiting on a semaphore and signaling that semaphore upon request sequence success, or upon terminal error in request sequence
- (void)performFetchWhileWaiting:(BOOL)isWaiting
{
    [DefaultsController addLogMessage:[NSString stringWithFormat:@"performFetchAndWait:%@", isWaiting ? @"YES" : @"NO"]];
    
    self.lastFetchAttempt = [NSDate date];
    self.isAttemptingReAuth = NO;
    
    [self internal_performFetchWhileWaiting:isWaiting];
    
    if (isWaiting) {
        dispatch_semaphore_wait(self.fetchSemaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)internal_performFetchWhileWaiting:(BOOL)isWaiting
{
    [DefaultsController addLogMessage:[NSString stringWithFormat:@"internal_performFetchWhileWaiting:%@", isWaiting ? @"YES" : @"NO"]];
    
    NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
    if (!authenticationPayload[@"accountName"] || !authenticationPayload[@"password"]) {
        [DefaultsController addLogMessage:@"watch app not authenitcated, skipping fetch attempt"];
        if (isWaiting) {
            dispatch_semaphore_signal(self.fetchSemaphore);
        }
        return;
    }
    
    if (!self.dexcomToken) {
        NSDictionary *authenticationPayload = [self.authenticationController authenticationPayload];
        [self authenticateWithDexcomAccountName:authenticationPayload[@"accountName"] andPassword:authenticationPayload[@"password"] isWaiting:isWaiting];
    } else {
        [self fetchLatestBloodSugarIsWaiting:isWaiting];
    }
}

- (void)authenticateWithDexcomAccountName:(NSString *)accountName andPassword:(NSString *)password isWaiting:(BOOL)isWaiting
{
    NSString *URLString = @"https://share2.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName";
    NSDictionary *parameters = @{@"accountName": accountName,
                                 @"password": password,
                                 @"applicationId": WSDexcomApplicationId_G5PlatinumApp};
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:parameters
                               withSuccessBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                   if (!isWaiting) {
                                       NSLog(@"received dexcom token: %@", responseObject);
                                   } else {
                                       [DefaultsController addLogMessage:[NSString stringWithFormat:@"received dexcom token: %@", responseObject]];
                                   }
                                   self.dexcomToken = responseObject;
                                   
                                   //assumption: every time the aplication authenticates, it next wants to fetch latest blood sugars
                                   [self fetchLatestBloodSugarIsWaiting:isWaiting];
                               }
                               withFailureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                   if (!isWaiting) {
                                       NSLog(@"error: %@", error);
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                                     isWaiting:isWaiting];
}

- (void)fetchLatestBloodSugarIsWaiting:(BOOL)isWaiting
{
    [DefaultsController addLogMessage:[NSString stringWithFormat:@"fetchLatestBloodSugarAndWait:%@", isWaiting ? @"YES" : @"NO"]];
    
    NSString *URLString = [NSString stringWithFormat:@"https://share2.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId=%@&minutes=1400&maxCount=1", self.dexcomToken];
    
    [WebRequestController dexcomPOSTToURLString:URLString
                                 withParameters:nil
                               withSuccessBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                   if (!isWaiting) {
                                       NSLog(@"received blood sugar data: %@", responseObject);
                                   } else {
                                       [DefaultsController addLogMessage:[NSString stringWithFormat:@"fetchLatestBloodSugarAndWait received blood sugar data: %@", responseObject]];
                                   }
                                   [self processLatestBloodSugarData:[responseObject firstObject] ? [responseObject firstObject] : nil isWaiting:isWaiting];
                               }
                               withFailureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                   NSDictionary *jsonError = [NSJSONSerialization JSONObjectWithData:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:0 error:NULL];
                                   if (!isWaiting) {
                                       NSLog(@"error: %@", error);
                                       if (jsonError) {
                                           NSLog(@"error response: %@", jsonError);
                                       } else {
                                           NSString *errorString = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                                           NSLog(@"%@", errorString);
                                       }
                                   } else {
                                       if (jsonError) {
                                           [DefaultsController addLogMessage:[NSString stringWithFormat:@"fetchLatestBloodSugarAndWait json error: %@", jsonError]];
                                       } else {
                                           NSString *errorString = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                                           [DefaultsController addLogMessage:[NSString stringWithFormat:@"fetchLatestBloodSugarAndWait error string: %@", errorString]];
                                       }
                                   }
                                   
                                   //if dexcom token has expired since last used, restart request sequence from beginning by authenticating anew
                                   if (!self.isAttemptingReAuth &&
                                       ([jsonError[@"Code"] isEqualToString:@"SessionNotValid"] ||
                                        [jsonError[@"Code"] isEqualToString:@"SessionIdNotFound"])
                                       ) {
                                       [DefaultsController addLogMessage:@"fetchLatestBloodSugarAndWait -> SessionNotValid"];
                                       
                                       self.isAttemptingReAuth = YES; //prevent infinite retries, is reset to NO on each top-level performFetchWhileWaiting: call
                                       
                                       self.dexcomToken = nil;
                                       
                                       [self internal_performFetchWhileWaiting:isWaiting];
                                   } else {
                                       dispatch_semaphore_signal(self.fetchSemaphore);
                                   }
                               }
                                     isWaiting:isWaiting];
}

- (void)processLatestBloodSugarData:(NSDictionary *)latestBloodSugarData isWaiting:(BOOL)isWaiting
{
    WSProcessReadingResult processResult = [DefaultsController processNewBloodSugarData:latestBloodSugarData];
    
    if (processResult == WSProcessReadingResultNewResultAdded) {
        
        //update complication, and if running in foreground, update UI
        for (CLKComplication *complication in [[CLKComplicationServer sharedInstance] activeComplications]) {
            [[CLKComplicationServer sharedInstance] reloadTimelineForComplication:complication];
        }
        
        if (!isWaiting) {
            [self.delegate webRequestControllerDidFetchNewBloodSugarData:self];
        }
        
        //log success
        NSDictionary *latestResult = [[DefaultsController latestBloodSugarReadings] lastObject];
        NSString *message = [NSString stringWithFormat:@"Save COMPLETE setLatestBloodSugarData:inBackground:%@, latest is now : %@", isWaiting ? @"YES" : @"NO", latestResult];
        if (!isWaiting) {
            NSLog(@"%@", message);
        } else {
            [DefaultsController addLogMessage:message];
        }
        
    } else {
        //log skip
        NSString *message = [NSString stringWithFormat:@"Save skipped setLatestBloodSugarData:%@ inBackground:%@", latestBloodSugarData, isWaiting ? @"YES" : @"NO"];
        if (!isWaiting) {
            NSLog(@"%@", message);
        } else {
            [DefaultsController addLogMessage:message];
        }
    }
    
    //this is the end of the request sequence, if the main thread is waiting on us, signal
    if (isWaiting) {
        dispatch_semaphore_signal(self.fetchSemaphore);
    }
}

@end
