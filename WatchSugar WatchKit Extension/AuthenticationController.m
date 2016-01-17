//
//  AuthenticationController.m
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import "AuthenticationController.h"
#import "UICKeyChainStore.h"

@implementation AuthenticationController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self authenticationPayload]; //getter loads from keychain
    }
    return self;
}

- (void)saveAuthenticationPayloadToKeychain:(NSDictionary *)authenticationPayload
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStore];
    keychain[@"accountName"] = authenticationPayload[@"accountName"];
    keychain[@"password"] = authenticationPayload[@"password"];
    
    self.authenticationPayload = authenticationPayload;
}

- (NSDictionary *)authenticationPayload
{
    if (!_authenticationPayload)
    {
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStore];
        
        if ([keychain contains:@"accountName"] && [keychain contains:@"password"]) {
            _authenticationPayload = @{
                                       @"accountName": keychain[@"accountName"],
                                       @"password": keychain[@"password"],
                                       };
        } else {
            _authenticationPayload = @{};
        }
    }
    
    return _authenticationPayload;
}

- (void)clearAuthenticationPayload
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStore];
    keychain[@"accountName"] = nil;
    keychain[@"password"] = nil;
    
    self.authenticationPayload = @{};
}

@end
