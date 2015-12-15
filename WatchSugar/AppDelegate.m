//
//  AppDelegate.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "AppDelegate.h"

#import <AFNetworking/AFNetworking.h>

@interface AppDelegate ()

@property (nonatomic, strong) NSString *dexcomToken;

@property (nonatomic, strong) NSTimer *fetchTimer;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
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
    
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:20.0f target:self selector:@selector(fetchTimerFired:) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

#pragma mark - Helper methods

- (void)fetchTimerFired:(NSTimer *)timer
{
    if (!self.dexcomToken) {
        [self authenticateWithDexcom];
    } else {
        [self fetchLatestBloodSugar];
    }
}

- (void)authenticateWithDexcom
{
    NSString *URLString = @"https://share1.dexcom.com/ShareWebServices/Services/General/AuthenticatePublisherAccount";
    NSDictionary *parameters = @{@"accountName": @"aawolf", @"password": @"Wuf*4646", @"applicationId": @"d8665ade-9673-4e27-9ff6-92db4ce13d13"};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];
    [manager setRequestSerializer:requestSerializer];
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager setResponseSerializer:responseSerializer];
    
    [manager POST:URLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask * task, id responseObject) {
        NSLog(@"received dexcom token: %@", responseObject);
        self.dexcomToken = responseObject;
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"error: %@", error);
    }];
}

- (void)fetchLatestBloodSugar
{
//    {
//        "Code": "SessionIdNotFound",
//        "Message": "Failed to find session object. [SessionId = 73b4c8d5-7605-4132-aa1d-39d2c80e93ec]",
//        "SubCode": "<OnlineException DateThrownLocal=\"2015-12-14 17:55:45.1463538-08:00\" DateThrown=\"2015-12-15 01:55:45.1463538+00:00\" ErrorCode=\"SessionIdNotFound\" Type=\"5\" Category=\"2\" Severity=\"2\" TypeString=\"ObjectNotFound\" CategoryString=\"Database\" SeverityString=\"Severe\" HostName=\"\" HostIP=\"\" Id=\"{BCA341F2-F252-4C9A-B671-39D4B586917A}\" Message=\"Failed to find session object. [SessionId = 73b4c8d5-7605-4132-aa1d-39d2c80e93ec]\" FullText=\"Dexcom.Common.OnlineException: Failed to find session object. [SessionId = 73b4c8d5-7605-4132-aa1d-39d2c80e93ec]\" \/>",
//        "TypeName": "FaultException"
//    }
    
    NSString *URLString = [NSString stringWithFormat:@"https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionID=%@&minutes=1440&maxCount=1", self.dexcomToken];
    NSString *parameters = nil;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];
    [manager setRequestSerializer:requestSerializer];
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager setResponseSerializer:responseSerializer];
    
    [manager POST:URLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask * task, id responseObject) {
        NSLog(@"received blood sugar data: %@", responseObject);
    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        NSLog(@"error: %@", error);
    }];
}

@end
