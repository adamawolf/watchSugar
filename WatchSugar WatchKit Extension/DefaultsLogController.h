//
//  DefaultsLogController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/13/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const WSDefaults_LogMessageArray;

@interface DefaultsLogController : NSObject

+ (void)addLogMessage:(NSString *)logMessage;

+ (NSArray <NSString *> *)allLogMessages;

+ (void)clearAllLogMessages;

@end
