//
//  ViewController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "ViewController.h"
#import "AuthenticationController.h"

@interface ViewController () <AuthenticationControllerDelegate>

@property (nonatomic, assign) WSLoginStatus renderedStatus;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [self.loginViews enumerateObjectsUsingBlock:^(UIView * view, NSUInteger idx, BOOL *stop) {
        view.alpha = 0.0f;
    }];
    
    [self.loggedInViews enumerateObjectsUsingBlock:^(UIView * view, NSUInteger idx, BOOL *stop) {
        view.alpha = 0.0f;
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.authenticationController.delegate = self;
    
    [self updateDisplayFromAuthenticationControllerAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.authenticationController.delegate = nil;
}

#pragma mark - Action methods

- (IBAction)loginButtonTapped:(id)sender
{
    [self.authenticationController changeToLoginStatus:WSLoginStatus_LoggedIn];
}

- (IBAction)logoutButtonTapped:(id)sender
{
    [self.authenticationController changeToLoginStatus:WSLoginStatus_NotLoggedIn];
}

#pragma mark - Helper methods

- (void)updateDisplayFromAuthenticationControllerAnimated:(BOOL)animated
{
    WSLoginStatus currentStatus = self.authenticationController.loginStatus;
    
    if (self.renderedStatus != currentStatus) {
        NSMutableArray <UIView *> *viewsToAppear = [NSMutableArray new];
        NSMutableArray <UIView *> *viewsToDisappear = [NSMutableArray new];
        
        switch (currentStatus) {
            case WSLoginStatus_NotLoggedIn:
                [viewsToAppear addObjectsFromArray:self.loginViews];
                [viewsToDisappear addObjectsFromArray:self.loggedInViews];
                break;
            case WSLoginStatus_LoggedIn:
                [viewsToAppear addObjectsFromArray:self.loggedInViews];
                [viewsToDisappear addObjectsFromArray:self.loginViews];
                break;
                
            default:
                break;
        }
        
        void(^appearBlock)() = ^() {
            [viewsToAppear enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
                obj.hidden = NO;
                obj.alpha = 1.0f;
            }];
        };
        
        void(^disappearBlock)() = ^() {
            [viewsToDisappear enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
                obj.alpha = 0.0f;
            }];
        };
        
        void(^disappearCompletionBlock)() = ^() {
            [viewsToDisappear enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
                obj.hidden = YES;
            }];
        };
        
        if (animated) {
            [UIView animateWithDuration:0.5f animations:disappearBlock completion:^(BOOL finished) {
                disappearCompletionBlock();
                [UIView animateWithDuration:0.5f animations:appearBlock];
            }];
        } else {
            disappearBlock();
            disappearCompletionBlock();
            appearBlock();
        }
    }
}

#pragma mark - AuthenticationControllerDelegate methods

- (void)authenticationController:(AuthenticationController *)authenticationController didChangeLoginStatus:(WSLoginStatus)loginStatus
{
    [self updateDisplayFromAuthenticationControllerAnimated:YES];
}

@end
