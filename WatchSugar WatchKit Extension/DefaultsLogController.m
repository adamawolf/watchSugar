//
//  DefaultsLogController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/13/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "DefaultsLogController.h"

NSString *const WSDefaults_LogMessageArray = @"WSDefaults_LogMessageArray";

@implementation DefaultsLogController

+ (void)addLogMessage:(NSString *)logMessage
{
    static NSDateFormatter *_logDateFormatter = nil;
    if (!_logDateFormatter) {
        _logDateFormatter = [[NSDateFormatter alloc] init];
        _logDateFormatter.dateStyle = NSDateFormatterShortStyle;
        _logDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    NSArray *logMessagesArray = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LogMessageArray];
    if (!logMessagesArray) {
        logMessagesArray = @[];
    }
    
    NSString * fullEntry = [NSString stringWithFormat:@"%@ - %@", [_logDateFormatter stringFromDate:[NSDate date]], logMessage];
    
    NSMutableArray *mutableLogMessagesArray = [logMessagesArray mutableCopy];
    [mutableLogMessagesArray addObject:fullEntry];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutableLogMessagesArray forKey:WSDefaults_LogMessageArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray <NSString *> *)allLogMessages
{
    NSArray <NSString *> *logMessagesArray = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LogMessageArray];
    if (!logMessagesArray) {
        logMessagesArray = @[];
    }
    
    return logMessagesArray;
}

+ (void)clearAllLogMessages
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LogMessageArray];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
