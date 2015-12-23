//
//  ViewController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *sessionIdLabel;
@property (nonatomic, strong) IBOutlet UILabel *subscriptionIdLabel;
@property (nonatomic, strong) IBOutlet UILabel *bloodSugarLabel;
@property (nonatomic, strong) IBOutlet UILabel *readingDateLabel;
@property (nonatomic, strong) IBOutlet UILabel *trendLabel;

@property (nonatomic, strong) IBOutlet UILabel *backgroundFetchCountLabel;
@property (nonatomic, strong) IBOutlet UILabel *backgroundFetchDateLabel;

- (void)updateDisplayWithSessionId:(NSString *)sessionId
                    subscriptionId:(NSString *)subscriptionId
           andBloodSugarDictionary:(NSDictionary *)bloodSugarDictionary
              backgroundFetchCount:(NSInteger)backgroundFetchCount
           lastBackgroundFetchDate:(NSDate *)lastBackgroundFetchDate;

@end

