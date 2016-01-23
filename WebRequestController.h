//
//  WebRequestController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/22/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const WSDexcomApplicationId_G5PlatinumApp;

@interface WebRequestController : NSObject

+ (void)dexcomPOSTToURLString:(NSString *)URLString
               withParameters:(id)parameters
             withSuccessBlock:(void (^)(NSURLSessionDataTask *, id))success
             withFailureBlock:(void (^)(NSURLSessionDataTask *, NSError *))failure
                   shouldWait:(BOOL)shouldWait;

@end
