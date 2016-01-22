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
#import "WebRequestController.h"

static const NSTimeInterval kMinimumRefreshInterval = 60.0f;

@interface InterfaceController() <WebRequestControllerDelegate>

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    NSLog(@"watch awakeWithContext");
}

- (void)willActivate
{
    [super willActivate];
    
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    WebRequestController *webRequestController = extensionDelegate.webRequestController;
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
    WebRequestController *webRequestController = extensionDelegate.webRequestController;
    webRequestController.delegate = nil;
    
    [super didDeactivate];
}

- (void)updateDisplay
{
    NSLog(@"watch updateDisplay");
    
    WSLoginStatus loginStatus = [DefaultsController lastKnownLoginStatus];
    
    if (loginStatus == WSLoginStatus_LoggedIn) {
        [self.bloodSugarLabel setHidden:NO];
        [self.readingDateLabel setHidden:NO];
        [self.trendImage setHidden:NO];
        [self.printLogButton setHidden:NO];
        [self.clearLogButton setHidden:NO];
        
        [self.notLoggedInLabel setHidden:YES];
        
        ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
        WebRequestController *webRequestController = extensionDelegate.webRequestController;
        
        if (!webRequestController.lastFetchAttempt || [[NSDate date] timeIntervalSinceDate:webRequestController.lastFetchAttempt] > kMinimumRefreshInterval) {
            [webRequestController performFetch];
        }
        
        NSArray *lastReadings = [DefaultsController latestBloodSugarReadings];

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

            self.readingDateLabel.text = [NSString stringWithFormat:@"from %@", [_timeStampDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch]]];
            
            int trend = [latestReading[@"trend"] intValue];
            NSString *trendImageName = [NSString stringWithFormat:@"trend_%d", trend];
            UIImage *trendImage = [UIImage imageNamed:trendImageName];
            trendImage = [trendImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.trendImage setImage:trendImage];
         
            [DefaultsController addLogMessage:[NSString stringWithFormat:@"InterfaceController updateDisplay: %@ %@", [NSString stringWithFormat:@"%d", mostRecentValue], [NSString stringWithFormat:@"from %@", [_timeStampDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch]]]]];
            
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
    NSLog(@"%@", [DefaultsController allLogMessages]);
}

- (IBAction)clearLogTapped:(id)sender
{
    [DefaultsController clearAllLogMessages];
}

#pragma mark - WebRequestControllerDelegate methods

- (void)webRequestControllerDidFetchNewBloodSugarData:(WebRequestController *)webRequestController
{
    [self updateDisplay];
}

@end
