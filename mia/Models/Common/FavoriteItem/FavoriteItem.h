//
//  FavoriteItem.h
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MusicItem.h"

@class ShareItem;

@interface FavoriteItem : NSObject <NSCoding>

@property (strong, nonatomic) NSString * sID;
@property (strong, nonatomic) NSString * uID;
@property (strong, nonatomic) NSString * sNick;
@property (strong, nonatomic) NSString * sDate;
@property (strong, nonatomic) NSString * sNote;
@property (strong, nonatomic) NSString * mID;
@property (strong, nonatomic) NSString * fID;

@property (strong, nonatomic) NSString * spID;
@property (assign, nonatomic) NSInteger time;
@property (assign, nonatomic) BOOL isInfected;

@property (strong, nonatomic) MusicItem *music;

@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL isCached;

@property (assign, nonatomic, readonly) ShareItem *shareItem;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
