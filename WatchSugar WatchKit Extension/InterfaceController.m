//
//  InterfaceController.m
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "InterfaceController.h"
#import "ExtensionDelegate.h"

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
    
    [self updateDisplay];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBloodSugarDataChanged:) name:WSNotificationBloodSugarDataChanged object:nil];
}

- (void)didDeactivate
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super didDeactivate];
}

- (void)updateDisplay
{
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    
    if (extensionDelegate.bloodSugarValues.count) {
        int mostRecentValue = [extensionDelegate.bloodSugarValues[0][@"value"] intValue];
        [self.bloodSugarLabel setText:[NSString stringWithFormat:@"%d", mostRecentValue]];
    } else {
        [self.bloodSugarLabel setText:@""];
    }
}

#pragma mark - Notification handler methods

- (void)handleBloodSugarDataChanged:(NSNotification *)notification
{
    [self updateDisplay];
}

@end
