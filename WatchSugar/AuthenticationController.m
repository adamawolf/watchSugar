//
//  AuthenticationController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "AuthenticationController.h"

NSString *const WSDefaults_LoginStatus = @"WSDefaults_LoginStatus";
NSString *const WSDefaults_LoggedInUsername  = @"WSDefaults_LoggedInUsername";
NSString *const WSDefaults_LoggedInEmail = @"WSDefaults_LoggedInEmail";

@implementation AuthenticationController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.loginStatus = [[NSUserDefaults standardUserDefaults] integerForKey:WSDefaults_LoginStatus];
        
        if (self.loginStatus == WSLoginStatus_None) {
            [self changeToLoginStatus:WSLoginStatus_NotLoggedIn];
        }
    }
    return self;
}

- (void)changeToLoginStatus:(WSLoginStatus)loginStatus
{
    self.loginStatus = loginStatus;
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.loginStatus forKey:WSDefaults_LoginStatus];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.delegate authenticationController:self didChangeLoginStatus:self.loginStatus];
}

@end
