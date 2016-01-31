//
//  InterfaceController.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "InterfaceController.h"
#import "ExtensionDelegate.h"

#import "DefaultsController.h"
#import "WatchWebRequestController.h"

#import <Parse/Parse.h>

static const NSTimeInterval kMinimumRefreshInterval = 60.0f;

@interface InterfaceController() <WatchWebRequestControllerDelegate>

@end

@implementation InterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];

    NSLog(@"watch awakeWithContext");
}

- (void)willActivate
{
    [super willActivate];
    
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    WatchWebRequestController *webRequestController = extensionDelegate.webRequestController;
    webRequestController.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive:) name:@"UIApplicationDidBecomeActiveNotification" object:nil];
}

- (void)didAppear
{
    [self updateDisplay];
}

- (void)didDeactivate
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    WatchWebRequestController *webRequestController = extensionDelegate.webRequestController;
    webRequestController.delegate = nil;
    
    [super didDeactivate];
}

- (void)updateDisplay
{
    WSLoginStatus loginStatus = [DefaultsController lastKnownLoginStatus];
    
    if (loginStatus == WSLoginStatus_LoggedIn) {
        [self.bloodSugarLabel setHidden:NO];
        [self.readingDateLabel setHidden:NO];
        [self.trendImage setHidden:NO];
        
#ifdef DEBUG
        [self.printLogButton setHidden:NO];
        [self.clearLogButton setHidden:YES];
#else
        [self.printLogButton setHidden:YES];
        [self.clearLogButton setHidden:YES];
#endif
        
        [self.notLoggedInLabel setHidden:YES];
        
        ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
        WatchWebRequestController *webRequestController = extensionDelegate.webRequestController;
        
        if (!webRequestController.lastFetchAttempt || [[NSDate date] timeIntervalSinceDate:webRequestController.lastFetchAttempt] > kMinimumRefreshInterval) {
            //clear dates used for processing background update metrics since this alters things
            [DefaultsController setLastNextRequestedUpdateDate:nil];
            [DefaultsController setLastUpdateStartDate:nil];
            
            [webRequestController performFetchWhileWaiting:NO];
        }
        
        NSArray *lastReadings = [DefaultsController latestBloodSugarReadings];

        if (lastReadings.count) {
            NSDictionary *latestReading = [lastReadings lastObject];
            
            if (latestReading[@"trend"] && latestReading[@"value"]) {
                int mostRecentValue = [latestReading[@"value"] intValue];
                self.bloodSugarLabel.text = [NSString stringWithFormat:@"%d", mostRecentValue];
                
                int trend = [latestReading[@"trend"] intValue];
                NSString *trendImageName = [NSString stringWithFormat:@"trend_%d", trend];
                UIImage *trendImage = [UIImage imageNamed:trendImageName];
                trendImage = [trendImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [self.trendImage setImage:trendImage];
            } else {
                self.bloodSugarLabel.text = @"No signal.";
                [self.trendImage setImage:nil];
            }
            
            NSTimeInterval epoch = [latestReading[@"timestamp"] doubleValue] / 1000.00; //dexcom dates include milliseconds
            
            static NSDateFormatter *_timeStampDateFormatter = nil;
            if (!_timeStampDateFormatter) {
                _timeStampDateFormatter = [[NSDateFormatter alloc] init];
                _timeStampDateFormatter.dateFormat = @"M-d h:mm a";
            }

            self.readingDateLabel.text = [NSString stringWithFormat:@"from %@", [_timeStampDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch]]];
        } else {
            self.bloodSugarLabel.text = @"--";
            self.readingDateLabel.text = @"";
            [self.trendImage setImage:nil];
        }
    } else {
        [self.bloodSugarLabel setHidden:YES];
        [self.readingDateLabel setHidden:YES];
        [self.trendImage setHidden:YES];
        [self.printLogButton setHidden:YES];
        [self.clearLogButton setHidden:YES];
        
        [self.notLoggedInLabel setHidden:NO];
    }
}

#pragma mark - Notification handler methods

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification
{
    [self updateDisplay];
}

#pragma mark -

- (IBAction)dumpLogTapped:(id)sender
{
    NSArray *actions = @[
                        [WKAlertAction actionWithTitle:@"Send" style:WKAlertActionStyleDefault handler:^{
                            PFObject *testObject = [PFObject objectWithClassName:@"Log"];
                            testObject[@"message"] = [DefaultsController allLogMessages];
                            [testObject saveInBackground];
                            
                            NSLog(@"%@", [DefaultsController allLogMessages]);
                        }],
                        [WKAlertAction actionWithTitle:@"Cancel" style:WKAlertActionStyleCancel handler:^{
                            NSLog(@"%@", [DefaultsController allLogMessages]);
                        }],
                        ];
    
    [self presentAlertControllerWithTitle:@"Send Logs"
                                  message:@"Please keep your wrist up for 10-20 seconds to complete."
                           preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

- (IBAction)clearLogTapped:(id)sender
{
    [DefaultsController clearAllLogMessages];
}

#pragma mark - WatchWebRequestControllerDelegate methods

- (void)webRequestControllerDidFetchNewBloodSugarData:(WatchWebRequestController *)webRequestController
{
    [self updateDisplay];
}

@end
