//
//  AuthenticationController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WSLoginStatus) {
    WSLoginStatus_None,
    WSLoginStatus_NotLoggedIn,
    WSLoginStatus_LoggedIn,
};

@interface AuthenticationController : NSObject

@property (nonatomic, strong) NSDictionary *authenticationPayload;

- (void)saveAuthenticationPayloadToKeychain:(NSDictionary *)authenticationPayload;
- (void)clearAuthenticationPayload;

@end
