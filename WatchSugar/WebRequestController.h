//
//  WebRequestController.h
//  WatchSugar
//
//  Created by Adam A. Wolf on 1/16/16.
//  Copyright © 2016 Flairify. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WebRequestControllerErrorCode) {
    WebRequestControllerErrorCode_UnknownError,
    WebRequestControllerErrorCode_InvalidRequest,
    WebRequestControllerErrorCode_AccountNotFound,
    WebRequestControllerErrorCode_InvalidPassword,
    WebRequestControllerErrorCode_MaxAttemptsReached,
};

@class WebRequestController;

@protocol WebRequestControllerDelegate <NSObject>

- (void)webRequestController:(WebRequestController *)webRequestController authenticationDidSucceedWithToken:(NSString *)token;
- (void)webRequestController:(WebRequestController *)webRequestController authenticationDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode;

- (void)webRequestController:(WebRequestController *)webRequestController displayNameRequestDidSucceedWithName:(NSString *)displayName;
- (void)webRequestController:(WebRequestController *)webRequestController displayNameRequestDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode;

- (void)webRequestController:(WebRequestController *)webRequestController emailRequestDidSucceedWithEmail:(NSString *)email;
- (void)webRequestController:(WebRequestController *)webRequestController emailRequestDidFailWithErrorCode:(WebRequestControllerErrorCode)errorCode;

@end

@interface WebRequestController : NSObject

@property (nonatomic, weak) id<WebRequestControllerDelegate> delegate;

- (void)authenticateWithDexcomAccountName:(NSString *)accountName andPassword:(NSString *)password;

- (void)readDexcomDisplayNameForToken:(NSString *)dexcomToken;
- (void)readDexcomEmailForToken:(NSString *)dexcomToken;

@end
