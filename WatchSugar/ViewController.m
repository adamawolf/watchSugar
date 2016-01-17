//
//  ViewController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 12/14/15.
//  Copyright © 2015 Flairify. All rights reserved.
//

#import "ViewController.h"
#import "AuthenticationController.h"
#import "WebRequestController.h"

@interface ViewController () <AuthenticationControllerDelegate, WebRequestControllerDelegate, UITextFieldDelegate>

@property (nonatomic, assign) WSLoginStatus renderedStatus;

@property (nonatomic, strong) NSString *errorMessage;

@property (nonatomic, strong) NSString *dexcomToken;
@property (nonatomic, strong) NSString *dexcomDisplayName;
@property (nonatomic, strong) NSString *dexcomEmail;

@property (nonatomic, strong) NSDictionary *pendingAuthenticationPayload;

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
    self.webRequestController.delegate = self;
    
    [self updateDisplayFromAuthenticationControllerAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.authenticationController.delegate = nil;
    self.webRequestController.delegate = nil;
}

#pragma mark - Action methods

- (IBAction)loginButtonTapped:(id)sender
{
    NSString *accountName = self.accountNameTextView.text;
    NSString *password = self.passwordTextView.text;
    
    if (accountName.length && password.length) {
        self.pendingAuthenticationPayload = @{
                                       @"accountName": accountName,
                                       @"password": password
                                       };
        [self updateDisplayFromAuthenticationControllerAnimated:NO];
        
        [self.webRequestController authenticateWithDexcomAccountName:accountName andPassword:password];
    } else {
        self.errorMessage = @"Account name and password required.";
        [self updateDisplayFromAuthenticationControllerAnimated:NO];
    }
}

- (IBAction)logoutButtonTapped:(id)sender
{
    self.accountNameTextView.text = nil;
    self.passwordTextView.text = nil;
    
    [self.authenticationController clearAuthenticationPayload];
    [self.authenticationController setDexcomDisplayName:nil andEmail:nil];
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
                if (self.errorMessage == nil) {
                    self.loginInformationLabel.text = @"Login to get started";
                    self.loginInformationLabel.textColor = [UIColor blackColor];
                } else {
                    self.loginInformationLabel.text = self.errorMessage;
                    self.loginInformationLabel.textColor = [UIColor redColor];
                }
                
                self.loginButton.enabled = !self.pendingAuthenticationPayload;
                
                [viewsToAppear addObjectsFromArray:self.loginViews];
                [viewsToDisappear addObjectsFromArray:self.loggedInViews];
                break;
            case WSLoginStatus_LoggedIn:
                [viewsToAppear addObjectsFromArray:self.loggedInViews];
                [viewsToDisappear addObjectsFromArray:self.loginViews];
                
                //input data into logged in fields
                self.displayNameLabel.text = self.authenticationController.displayName;
                self.emailLabel.text = self.authenticationController.email;
                
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
    
    DDLogDebug(@"current saved authentication payload: %@", [self.authenticationController authenticationPayload]);
}

- (void)checkForCompleteAuthentication
{
    if (self.dexcomToken && self.dexcomDisplayName && self.dexcomEmail) {
        [self.authenticationController saveAuthenticationPayloadToKeychain:self.pendingAuthenticationPayload];
        self.pendingAuthenticationPayload = nil;
        
        [self.authenticationController setDexcomDisplayName:self.dexcomDisplayName andEmail:self.dexcomEmail];
        self.dexcomToken = self.dexcomDisplayName = self.dexcomEmail = nil;
        [self.authenticationController changeToLoginStatus:WSLoginStatus_LoggedIn];
    }
}

#pragma mark - AuthenticationControllerDelegate methods

- (void)authenticationController:(AuthenticationController *)authenticationController didChangeLoginStatus:(WSLoginStatus)loginStatus
{
    [self updateDisplayFromAuthenticationControllerAnimated:YES];
}

#pragma mark - WebRequestControllerDelegate methods

- (void)webRequestController:(WebRequestController *)webRequestController authenticationDidSucceedWithToken:(NSString *)token
{
    self.dexcomToken = token;

    [self.webRequestController readDexcomDisplayNameForToken:self.dexcomToken];
    [self.webRequestController readDexcomEmailForToken:self.dexcomToken];
}

- (void)webRequestController:(WebRequestController *)webRequestController authenticationDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode
{
    switch (errorCode) {
        case WebRequestControllerErrorCode_AccountNotFound:
            self.errorMessage = @"Error: Account name not found.";
            break;
            
        case WebRequestControllerErrorCode_InvalidPassword:
            self.errorMessage = @"Error: Invalid password.";
            break;
            
        case WebRequestControllerErrorCode_MaxAttemptsReached:
            self.errorMessage = @"Error: Max login attempts. Wait 10 minutes.";
            break;
            
        default:
            self.errorMessage = @"Error: Unknown error, please check your connection.";
            break;
            
    }
    
    self.pendingAuthenticationPayload = nil;
    [self updateDisplayFromAuthenticationControllerAnimated:NO];
}

- (void)webRequestController:(WebRequestController *)webRequestController displayNameRequestDidSucceedWithName:(NSString *)displayName
{
    self.dexcomDisplayName = displayName;
    
    [self checkForCompleteAuthentication];
}

- (void)webRequestController:(WebRequestController *)webRequestController displayNameRequestDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode
{
    self.errorMessage = @"Unexpected behavior after authentication. Please report.";
    
    self.dexcomToken = nil;
    self.dexcomEmail = nil;
    
    self.pendingAuthenticationPayload = nil;
    [self updateDisplayFromAuthenticationControllerAnimated:NO];
}

- (void)webRequestController:(WebRequestController *)webRequestController emailRequestDidSucceedWithEmail:(NSString *)email
{
    self.dexcomEmail = email;
    
    [self checkForCompleteAuthentication];
}

- (void)webRequestController:(WebRequestController *)webRequestController emailRequestDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode
{
    self.errorMessage = @"Unexpected behavior after authentication. Please report.";
    
    self.dexcomToken = nil;
    self.dexcomEmail = nil;

    self.pendingAuthenticationPayload = nil;
    [self updateDisplayFromAuthenticationControllerAnimated:NO];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.accountNameTextView) {
        [self.passwordTextView becomeFirstResponder];
    } else {
        [self.passwordTextView resignFirstResponder];
        
        [self loginButtonTapped:self.loginButton];
    }
    
    return YES;
}

@end
