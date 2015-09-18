//
//  RadioView.h
//  mia
//
//  Created by linyehui on 2015/09/09.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareItem.h"
#import "LoopPlayerView.h"
@protocol RadioViewDelegate

@end


@interface RadioView : UIView <LoopPlayerViewDelegate>

@property (weak, nonatomic)id<RadioViewDelegate> radioViewDelegate;

- (void)handleNearbyFeeds:(NSDictionary *)userInfo;
- (void)setShareItem:(ShareItem *)item;

- (void)spreadFeed;
- (void)skipFeed;

@end
