//
//  WebRequestController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/22/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "WebRequestController.h"
#import <AFNetworking/AFNetworking.h>
#import "Definitions.h"

NSString *const WSDexcomApplicationId_G5PlatinumApp = WSDexcomApplicationId;

@implementation WebRequestController

+ (void)dexcomPOSTToURLString:(NSString *)URLString
               withParameters:(id)parameters
             withSuccessBlock:(void (^)(NSURLSessionDataTask *, id))success
             withFailureBlock:(void (^)(NSURLSessionDataTask *, NSError *))failure
                   isWaiting:(BOOL)isWaiting
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    if (isWaiting) {
        //when called from ComplicationController, we block on main thread with semaphores while web requests occur
        //this would cause a deadlock for the success or failure call backs, hence if waiting we use a background queue
        manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    }
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager setRequestSerializer:requestSerializer];
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager setResponseSerializer:responseSerializer];
    
    [manager POST:URLString parameters:parameters progress:NULL success:success failure:failure];
}

@end
