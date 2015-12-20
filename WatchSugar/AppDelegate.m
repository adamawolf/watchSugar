//
//  AppDelegate.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "AppDelegate.h"

#import <AFNetworking/AFNetworking.h>

#import <MagicalRecord/MagicalRecord.h>
#import "Reading+CoreDataProperties.h"

#import <WatchConnectivity/WatchConnectivity.h>

NSString *const WSNotificationDexcomDataChanged = @"WSNotificationDexcomDataChanged";

static const NSTimeInterval kRefreshInterval = 120.0f; //seconds

@interface AppDelegate () <WCSessionDelegate>

@property (nonatomic, strong) NSTimer *fetchTimer;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //initialize CoreData
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"WatchSugar"];
    
    NSLog(@"%@", [MagicalRecord currentStack]);
    
    //initialize WatchConnectivity
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (self.fetchTimer) {
        [self.fetchTimer invalidate];
        self.fetchTimer = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!self.dexcomToken) {
        [self authenticateWithDexcom];
    }
    
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshInterval target:self selector:@selector(fetchTimerFired:) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

#pragma mark - Helper methods

- (void)fetchTimerFired:(NSTimer *)timer
{
    if (!self.dexcomToken) {
        [self authenticateWithDexcom];
    } else {
        if (!self.subscriptionId) {
            [self fetchSubscriptions];
        } else {
            [self fetchLatestBloodSugar];
        }
    }
}

+ (void)dexcomPOSTToURLString:(NSString *)URLString
               withParameters:(id)parameters
             withSuccessBlock:(void (^)(NSURLSessionDataTask *, id))success
             withFailureBlock:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];
    [manager setRequestSerializer:requestSerializer];
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager setResponseSerializer:responseSerializer];
    
    [manager POST:URLString parameters:parameters progress:NULL success:success failure:failure];
}

- (void)authenticateWithDexcom
{
    NSString *URLString = @"https://share1.dexcom.com/ShareWebServices/Services/General/LoginSubscriberAccount";
    NSDictionary *parameters = @{@"accountId": @"***REMOVED***",
                                 @"password": @"A***REMOVED***",
                                 @"applicationId": @"d89443d2-327c-4a6f-89e5-496bbb0317db"};
    
    [AppDelegate dexcomPOSTToURLString:URLString
                        withParameters:parameters
                      withSuccessBlock:^(NSURLSessionDataTask * task, id responseObject) {
                          NSLog(@"received dexcom token: %@", responseObject);
                          self.dexcomToken = responseObject;
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationDexcomDataChanged object:nil userInfo:nil];
                          
                          if (!self.subscriptionId) {
                              [self fetchSubscriptions];
                          }
                      }
                      withFailureBlock:^(NSURLSessionDataTask * task, NSError * error) {
                          NSLog(@"error: %@", error);
                      }];
}

- (void)fetchSubscriptions
{
    NSString *URLString = [NSString stringWithFormat:@"https://share1.dexcom.com/ShareWebServices/Services/Subscriber/ListSubscriberAccountSubscriptions?sessionId=%@", self.dexcomToken];
    NSString *parameters = nil;
    
    [AppDelegate dexcomPOSTToURLString:URLString
                        withParameters:parameters
                      withSuccessBlock:^(NSURLSessionDataTask * task, id responseObject) {
                          NSLog(@"received subscription list: %@", responseObject);
                          self.subscriptionId = responseObject[0][@"SubscriptionId"];
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationDexcomDataChanged object:nil userInfo:nil];
                          
                          if (!self.latestBloodSugarData) {
                              [self fetchLatestBloodSugar];
                          }
                      }
                      withFailureBlock:^(NSURLSessionDataTask * task, NSError * error) {
                          NSLog(@"error: %@", error);
                      }];
}

- (void)fetchLatestBloodSugar
{
    NSString *URLString = [NSString stringWithFormat:@"https://share1.dexcom.com/ShareWebServices/Services/Subscriber/ReadLastGlucoseFromSubscriptions?sessionId=%@", self.dexcomToken];
    NSArray *parameters = @[self.subscriptionId];
    
    [AppDelegate dexcomPOSTToURLString:URLString
                        withParameters:parameters
                      withSuccessBlock:^(NSURLSessionDataTask * task, id responseObject) {
                          NSLog(@"received blood sugar data: %@", responseObject);
                          self.latestBloodSugarData = responseObject[0][@"Egv"];
                      }
                      withFailureBlock:^(NSURLSessionDataTask * task, NSError * error) {
                          NSLog(@"error: %@", error);
                      }];
}

- (void)sendAllBloodSugarReadingsFromPastDay
{
    if ([[WCSession defaultSession] isReachable]) {
        int64_t dayAgoEpochMilliseconds = (int64_t)([[NSDate date] timeIntervalSince1970] - (24 * 60 * 60)) * 1000;
        NSArray *allReadings = [Reading MR_findAllSortedBy:@"timestamp" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"timestamp > %ld", dayAgoEpochMilliseconds]];
        
        NSMutableArray *allReadingDicts = [NSMutableArray new];
        [allReadings enumerateObjectsUsingBlock:^(Reading *obj, NSUInteger idx, BOOL *stop) {
            [allReadingDicts addObject:@{
                                         @"timestamp": obj.timestamp,
                                         @"value": obj.value,
                                         @"trend": obj.trend,
                                         }];
        }];
        
        [[WCSession defaultSession] sendMessage:@{@"readings": allReadingDicts}
                                   replyHandler:^(NSDictionary *reply) {
                                       NSLog(@"device app received reply: %@", reply);
                                   }
                                   errorHandler:^(NSError *error) {
                                       NSLog(@"device app received error: %@", error);
                                   }
         ];
    }
}

#pragma mark - Custom setter methods

-(void)setLatestBloodSugarData:(NSDictionary *)latestBloodSugarData
{
    _latestBloodSugarData = latestBloodSugarData;
    
    if (_latestBloodSugarData) {
        
        Reading * latestReading = [Reading MR_findFirstOrderedByAttribute:@"timestamp" ascending:NO];
        NSString *STDate = [_latestBloodSugarData[@"ST"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]][1];
        int64_t epochMilliseconds = [STDate longLongValue];
        if ([latestReading.timestamp longLongValue] != epochMilliseconds)
        {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Reading *newReading = [Reading MR_createEntityInContext:localContext];
                newReading.timestamp = @(epochMilliseconds);
                newReading.trend = _latestBloodSugarData[@"Trend"];
                newReading.value = _latestBloodSugarData[@"Value"];
            } completion:^(BOOL contextDidSave, NSError *error) {
                [self sendAllBloodSugarReadingsFromPastDay];
            }];
        } else {
            NSLog(@"Latest Egv value has already been saved to Core Data. Skipping.");
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WSNotificationDexcomDataChanged object:nil userInfo:nil];
    }
}

#pragma mark - WCSessionDelegate methods

- (void)sessionWatchStateDidChange:(WCSession *)session
{
    if (session.isReachable) {
        [self sendAllBloodSugarReadingsFromPastDay];
    }
}

@end
