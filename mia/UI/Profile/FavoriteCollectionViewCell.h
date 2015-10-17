//
//  FavoriteCollectionViewCell.h
//  mia
//
//  Created by linyehui on 2015-09-20.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoriteItem.h"

@interface FavoriteCollectionViewCell : UICollectionViewCell

@property (assign, nonatomic) BOOL isEditing;
@property(assign, nonatomic) NSInteger rowIndex;
@property (strong, nonatomic) FavoriteItem *dataItem;

- (void)updatePlayingState;
- (void)updateSelectedState;

@end