//
//  WebRequestController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebRequestController.h"

typedef NS_ENUM(NSUInteger, WebRequestControllerErrorCode) {
    WebRequestControllerErrorCode_UnknownError,
    WebRequestControllerErrorCode_InvalidRequest,
    WebRequestControllerErrorCode_AccountNotFound,
    WebRequestControllerErrorCode_InvalidPassword,
    WebRequestControllerErrorCode_MaxAttemptsReached,
};

@class DeviceWebRequestController;

@protocol DeviceWebRequestControllerDelegate <NSObject>

- (void)webRequestController:(DeviceWebRequestController *)webRequestController authenticationDidSucceedWithToken:(NSString *)token;
- (void)webRequestController:(DeviceWebRequestController *)webRequestController authenticationDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode;

- (void)webRequestController:(DeviceWebRequestController *)webRequestController displayNameRequestDidSucceedWithName:(NSString *)displayName;
- (void)webRequestController:(DeviceWebRequestController *)webRequestController displayNameRequestDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode;

- (void)webRequestController:(DeviceWebRequestController *)webRequestController emailRequestDidSucceedWithEmail:(NSString *)email;
- (void)webRequestController:(DeviceWebRequestController *)webRequestController emailRequestDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode;

@end

@interface DeviceWebRequestController : WebRequestController

@property (nonatomic, weak) id<DeviceWebRequestControllerDelegate> delegate;

- (void)authenticateWithDexcomAccountName:(NSString *)accountName andPassword:(NSString *)password;

- (void)readDexcomDisplayNameForToken:(NSString *)dexcomToken;
- (void)readDexcomEmailForToken:(NSString *)dexcomToken;

@end
