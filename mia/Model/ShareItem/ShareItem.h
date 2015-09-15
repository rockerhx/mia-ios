//
//  ShareItem.h
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "MusicItem.h"

@interface ShareItem : NSObject

@property (strong, nonatomic) NSString *spID;
@property (strong, nonatomic) NSString *sID;
@property (strong, nonatomic) NSString *uID;
@property (strong, nonatomic) NSString *sNick;
@property (strong, nonatomic) NSString *sNote;
@property (assign, nonatomic) int cView;
@property (assign, nonatomic) int cComm;
@property (strong, nonatomic) NSString *sAddress;
@property (strong, nonatomic) NSString *sLongitude;
@property (strong, nonatomic) NSString *sLatitude;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end