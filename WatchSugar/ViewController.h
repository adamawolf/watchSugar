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

@end

