//
//  InterfaceController.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "InterfaceController.h"
#import "ExtensionDelegate.h"

#import "DefaultsLogController.h"

static const NSTimeInterval kMinimumRefreshInterval = 60.0f;

@interface InterfaceController()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    NSLog(@"watch awakeWithContext");
}

- (void)willActivate
{
    [super willActivate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBloodSugarDataChanged:) name:WSNotificationDexcomDataChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive:) name:@"UIApplicationDidBecomeActiveNotification" object:nil];
}

- (void)didAppear
{
    [self updateDisplay]; 
}

- (void)didDeactivate
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super didDeactivate];
}

- (void)updateDisplay
{
    NSLog(@"watch updateDisplay");
    
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    WebRequestController *webRequestController = extensionDelegate.webRequestController;
    
    if (!webRequestController.lastFetchAttempt || [[NSDate date] timeIntervalSinceDate:webRequestController.lastFetchAttempt] > kMinimumRefreshInterval) {
        [webRequestController performFetch];
    }
    
    NSArray *lastReadings = [[NSUserDefaults standardUserDefaults] arrayForKey:WSDefaults_LastReadings];

    if (lastReadings.count) {
        NSDictionary *latestReading = [lastReadings lastObject];
        
        int mostRecentValue = [latestReading[@"value"] intValue];
        self.bloodSugarLabel.text = [NSString stringWithFormat:@"%d", mostRecentValue];
        
        NSTimeInterval epoch = [latestReading[@"timestamp"] doubleValue] / 1000.00; //dexcom dates include milliseconds
        
        static NSDateFormatter *_timeStampDateFormatter = nil;
        if (!_timeStampDateFormatter) {
            _timeStampDateFormatter = [[NSDateFormatter alloc] init];
            _timeStampDateFormatter.dateFormat = @"M-d h:mm a";
        }

        self.agoLabel.text = [NSString stringWithFormat:@"from %@", [_timeStampDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch]]];
        
        int trend = [latestReading[@"trend"] intValue];
        NSString *trendImageName = [NSString stringWithFormat:@"trend_%d", trend];
        UIImage *trendImage = [UIImage imageNamed:trendImageName];
        trendImage = [trendImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.trendImage setImage:trendImage];
        
    } else {
        self.bloodSugarLabel.text = @"--";
        self.agoLabel.text = @"";
        self.trendLabel.text = @"";
    }
}

#pragma mark - Notification handler methods

- (void)handleBloodSugarDataChanged:(NSNotification *)notification
{
    [self updateDisplay];
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification
{
    [self updateDisplay];
}

#pragma mark -

- (IBAction)dumpLogTapped:(id)sender
{
    NSLog(@"%@", [DefaultsLogController allLogMessages]);
}

- (IBAction)clearLogTapped:(id)sender
{
    [DefaultsLogController clearAllLogMessages];
}

@end
