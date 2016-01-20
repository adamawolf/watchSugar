//
//  InterfaceController.h
//  WatchSugar WatchKit Extension
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController : WKInterfaceController <WCSessionDelegate>

@property (nonatomic, strong) IBOutlet WKInterfaceLabel *bloodSugarLabel;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *agoLabel;
@property (nonatomic, strong) IBOutlet WKInterfaceImage *trendImage;
@property (nonatomic, strong) IBOutlet WKInterfaceButton *printLogButton;
@property (nonatomic, strong) IBOutlet WKInterfaceButton *clearLogButton;

@property (nonatomic, strong) IBOutlet WKInterfaceLabel *notLoggedInLabel;

- (void)updateDisplay;

- (IBAction)dumpLogTapped:(id)sender;
- (IBAction)clearLogTapped:(id)sender;

@end
