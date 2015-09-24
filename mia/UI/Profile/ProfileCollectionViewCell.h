//
//  ProfileCollectionViewCell.h
//  mia
//
//  Created by linyehui on 2015-09-20.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareItem.h"

@interface ProfileCollectionViewCell : UICollectionViewCell

@property (assign, nonatomic) BOOL isBiggerCell;
@property (assign, nonatomic) BOOL isMyProfile;
@property (strong, nonatomic) ShareItem *shareItem;

@end