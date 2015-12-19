//
//  ViewController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.bloodSugarLabel.text = @"";
    self.readingDateLabel.text = @"";
    self.trendLabel.text = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dexcomDataDidChange:) name:WSNotificationDexcomDataChanged object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification handler methods

- (void)dexcomDataDidChange:(NSNotification *)notification
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self updateDisplayWithSessionId:appDelegate.dexcomToken subscriptionId:appDelegate.subscriptionId andBloodSugarDictionary:appDelegate.latestBloodSugarData];
}

#pragma mark - Helper methods

- (void)updateDisplayWithSessionId:(NSString *)sessionId
                    subscriptionId:(NSString *)subscriptionId
           andBloodSugarDictionary:(NSDictionary *)bloodSugarDictionary
{
    self.sessionIdLabel.text = sessionId;
    self.subscriptionIdLabel.text = subscriptionId;
    
    if (bloodSugarDictionary) {
        self.bloodSugarLabel.text =[NSString stringWithFormat:@"%d mg/dL", [bloodSugarDictionary[@"Value"] intValue]];
        
        NSString *epochAsString = [bloodSugarDictionary[@"ST"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]][1];
        NSTimeInterval epoch = [epochAsString doubleValue] / 1000.00; //dexcom dates include milliseconds
        NSString *agoString = [ViewController humanHourMinuteSecondStringFromTimeInterval:[[NSDate date] timeIntervalSince1970] - epoch];
        self.readingDateLabel.text = [NSString stringWithFormat:@"%@ ago", agoString];
        
        self.trendLabel.text = [NSString stringWithFormat:@"%d", [bloodSugarDictionary[@"Trend"] intValue]];
    } else {
        self.bloodSugarLabel.text = @"";
        self.readingDateLabel.text = @"";
        self.trendLabel.text = @"";
    }
}

+ (NSString *) humanHourMinuteSecondStringFromTimeInterval: (NSTimeInterval) timeInterval;
{
    NSString * ret = nil;
    
    if (timeInterval < 60)
    {
        ret = [NSString stringWithFormat:@"%ds", (int)timeInterval];
    }
    else if (timeInterval < 60 * 60)
    {
        NSInteger minutes = (NSInteger)(timeInterval / 60);
        timeInterval -= minutes * 60;
        NSInteger seconds = (NSInteger)(timeInterval);
        ret = [NSString stringWithFormat:@"%dm", (int)minutes];
        if (seconds)
        {
            ret = [NSString stringWithFormat:@"%@ %ds", ret, (int)seconds];
        }
    }
    else if (timeInterval < 60 * 60 * 24)
    {
        NSInteger hours = (NSInteger)(timeInterval / (60 * 60));
        ret = [NSString stringWithFormat:@"%dh", (int)hours];
        timeInterval -= hours * 60 * 60;
        NSInteger minutes = (NSInteger)(timeInterval / 60);
        if (minutes)
        {
            ret = [NSString stringWithFormat:@"%@%dm", ret, (int)minutes];
        }
    }
    else
    {
        NSInteger days = (NSInteger)(timeInterval / (24 * 60 * 60));
        ret = [NSString stringWithFormat:@"%dd", (int)days];
        timeInterval -= days * 24 * 60 * 60;
        NSInteger hours = (NSInteger)(timeInterval / (60 * 60));
        if (hours)
        {
            ret = [NSString stringWithFormat:@"%@%dh", ret, (int)hours];
        }
    }
    
    return ret;
}

@end
