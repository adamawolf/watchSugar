//
//  AuthenticationController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "AuthenticationController.h"
#import "UICKeyChainStore.h"

NSString *const WSDefaults_LoginStatus = @"WSDefaults_LoginStatus";
NSString *const WSDefaults_LoggedInDisplayName  = @"WSDefaults_LoggedInDisplayName";
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
        
        self.displayName = [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_LoggedInDisplayName];
        self.email = [[NSUserDefaults standardUserDefaults] objectForKey:WSDefaults_LoggedInEmail];
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

- (void)saveAuthenticationPayloadToKeychain:(NSDictionary *)authenticationPayload
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStore];
    keychain[@"accountName"] = authenticationPayload[@"accountName"];
    keychain[@"password"] = authenticationPayload[@"password"];
}

- (NSDictionary *)authenticationPayload
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStore];
    
    if ([keychain contains:@"accountName"] && [keychain contains:@"password"]) {
        return @{
                 @"accountName": keychain[@"accountName"],
                 @"password": keychain[@"password"],
                 };
    } else {
        return nil;
    }
}

- (void)clearAuthenticationPayload
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStore];
    keychain[@"accountName"] = nil;
    keychain[@"password"] = nil;
}

- (void)setDexcomDisplayName:(NSString *)displayName andEmail:(NSString *)email
{
    self.displayName = displayName;
    
    if (self.displayName == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LoggedInDisplayName];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:self.displayName forKey:WSDefaults_LoggedInDisplayName];
    }
    
    self.email = email;
    
    if (self.email == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:WSDefaults_LoggedInEmail];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:self.email forKey:WSDefaults_LoggedInEmail];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
