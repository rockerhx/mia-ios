//
//  MiaAPIHelper.h
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "MiaAPIMacro.h"

@interface MiaAPIHelper : NSObject

+ (id)getUUID;
+ (void)sendUUID;
+ (void)getNearbyWithLatitude:(float)lat longitude:(float) lon start:(long) start item:(long) item;
+ (void)getMusicCommentWithShareID:(NSString *)sID start:(long) start item:(long) item;

+ (void)InfectMusicWithLatitude:(float)lat longitude:(float) lon address:(NSString *)address spID:(NSString *)spID;
+ (void)SkipMusicWithLatitude:(float)lat longitude:(float) lon address:(NSString *)address spID:(NSString *)spID;

+ (void)getVerificationCodeWithType:(long)type phoneNumber:(NSString *)phoneNumber;
+ (void)registerWithPhoneNum:(NSString *)phoneNumber scode:(NSString *)scode nickName:(NSString *)nickName password:(NSString *)password;
+ (void)resetPasswordWithPhoneNum:(NSString *)phoneNumber password:(NSString *)password scode:(NSString *)scode;
+ (void)loginWithPhoneNum:(NSString *)phoneNumber password:(NSString *)password;

@end
