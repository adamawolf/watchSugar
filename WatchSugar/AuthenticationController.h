//
//  AuthenticationController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const WSDefaults_LoginStatus;
extern NSString *const WSDefaults_LoggedInUsername;
extern NSString *const WSDefaults_LoggedInEmail;

typedef NS_ENUM(NSUInteger, WSLoginStatus) {
    WSLoginStatus_None,
    WSLoginStatus_NotLoggedIn,
    WSLoginStatus_LoggedIn,
};

@class AuthenticationController;

@protocol AuthenticationControllerDelegate <NSObject>

- (void)authenticationController:(AuthenticationController *)authenticationController didChangeLoginStatus:(WSLoginStatus)loginStatus;

@end

@interface AuthenticationController : NSObject

@property (nonatomic, assign) WSLoginStatus loginStatus;

@property (nonatomic, weak) id<AuthenticationControllerDelegate> delegate;

- (void)changeToLoginStatus:(WSLoginStatus)loginStatus;

@end
