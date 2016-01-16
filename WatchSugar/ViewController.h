//
//  ViewController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AuthenticationController;

@interface ViewController : UIViewController

@property (nonatomic, strong) AuthenticationController *authenticationController;

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray <UIView *> *loginViews;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray <UIView *> *loggedInViews;

- (IBAction)loginButtonTapped:(id)sender;
- (IBAction)logoutButtonTapped:(id)sender;

@end

