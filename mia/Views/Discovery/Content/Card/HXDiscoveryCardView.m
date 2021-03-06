//
//  HXDiscoveryCardView.m
//  mia
//
//  Created by miaios on 16/2/18.
//  Copyright © 2016年 Mia Music. All rights reserved.
//

#import "HXDiscoveryCardView.h"
#import "HXXib.h"
#import "ShareItem.h"
#import "HXDiscoveryCover.h"
#import "TTTAttributedLabel.h"
#import "HXInfectView.h"
#import "UIConstants.h"
#import "HXUserSession.h"
#import "MiaAPIHelper.h"
#import "FavoriteMgr.h"
#import "HXAlertBanner.h"
#import "WebSocketMgr.h"
#import "NSObject+LoginAction.h"
#import "UIView+Frame.h"
#import "HXVersion.h"

@interface HXDiscoveryCardView () <
HXDiscoveryCoverDelegate,
TTTAttributedLabelDelegate,
HXInfectViewDelegate
>
@end

@implementation HXDiscoveryCardView {
    CAShapeLayer *_sharerNickNameLayer;
    __weak ShareItem *_shareItem;
}

HXXibImplementation

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _sharerLabel.preferredMaxLayoutWidth = self.width - 30.0f;
    
    if ([HXVersion currentModel] == SCDeviceModelTypeIphone5_5S) {
        _cverToShareInfoLabelVerticalSpaceConstraint.constant = 12.0f;
        _shareInfoLabelToInfectViewVerticalSpaceConstraint.constant = 12.0f;
        _infectViewToFavoriteViewVerticalSpaceConstraint.constant = 6.0f;
        _favoriteViewToCommentViewVerticalSpaceConstraint.constant = 0.0f;
        _commentViewToSuperViewVerticalSpaceConstraint.constant = 8.0f;
    }
}

#pragma mark - Event Response
- (IBAction)favoriteAction {
    if ([HXUserSession share].userState) {
        [MiaAPIHelper favoriteMusicWithShareID:_shareItem.sID
                                    isFavorite:!_shareItem.favorite
                                 completeBlock:
         ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
             if (success) {
                 id act = userInfo[MiaAPIKey_Values][@"act"];
                 id sID = userInfo[MiaAPIKey_Values][@"id"];
                 BOOL favorite = [act intValue];
                 if ([_shareItem.sID integerValue] == [sID intValue]) {
                     _shareItem.favorite = favorite;
                 }
                 
                 _shareItem.starCnt += (favorite ? 1 : (_shareItem.starCnt ? -1 : 0));
                 _favoriteIcon.image = [UIImage imageNamed:(favorite ? @"D-FavoritedIcon" : @"D-FavoriteIcon")];
                 [self displayWithItem:_shareItem];
                 
                 [HXAlertBanner showWithMessage:(favorite ? @"收藏成功" : @"取消收藏成功") tap:nil];
                 
                 // 收藏操作成功后同步下收藏列表并检查下载
                 [[FavoriteMgr standard] syncFavoriteList];
             } else {
                 id error = userInfo[MiaAPIKey_Values][MiaAPIKey_Error];
                 [HXAlertBanner showWithMessage:[NSString stringWithFormat:@"%@", error] tap:nil];
             }
         } timeoutBlock:^(MiaRequestItem *requestItem) {
             [HXAlertBanner showWithMessage:@"收藏失败，网络请求超时" tap:nil];
         }];
    } else {
        [self shouldLogin];
    }
}

- (IBAction)showCommenterAction {
    if (_delegate && [_delegate respondsToSelector:@selector(cardView:takeAction:)]) {
        [_delegate cardView:self takeAction:HXDiscoveryCardViewActionShowCommenter];
    }
}

- (IBAction)showCommentAction {
    if (_delegate && [_delegate respondsToSelector:@selector(cardView:takeAction:)]) {
        [_delegate cardView:self takeAction:HXDiscoveryCardViewActionComment];
    }
}

- (IBAction)showDetailAction {
    if (_delegate && [_delegate respondsToSelector:@selector(cardView:takeAction:)]) {
        [_delegate cardView:self takeAction:HXDiscoveryCardViewActionShowDetailAndComment];
    }
}

#pragma mark - Public Methods
- (void)displayWithItem:(id)item {
    if ([item isKindOfClass:[ShareItem class]]) {
        _shareItem = item;
        [_coverView displayWithItem:_shareItem];
        [self displaySharerLabelWithSharer:_shareItem.sNick content:_shareItem.sNote];
        
        _infectView.infected = _shareItem.isInfected;
        [_infectView setInfecters:_shareItem.infectUsers];
        
        _favoriteIcon.image = [UIImage imageNamed:(_shareItem.favorite ? @"D-FavoritedIcon" : @"D-FavoriteIcon")];
        _favoriteCountLabel.text = [@(_shareItem.starCnt).stringValue stringByAppendingString:@"人收藏"];
        
        LastCommentItem *comment = _shareItem.lastComment;
        _commentatorsNameLabel.text = (comment.nick ?: ([HXUserSession share].user.nickName ?: @"快来"));
        _commentContentLabel.text = comment.comment ?: @"说说你此刻的想法...";
    }
}

#pragma mark - Private Methods
- (void)displaySharerLabelWithSharer:(NSString *)sharer content:(NSString *)content {
    if (!sharer || !content) {
        return;
    }
    
    NSString *sharerString = [NSString stringWithFormat:@"  %@  ", sharer];
    NSString *shareContent = [NSString stringWithFormat:@"%@  %@", sharerString, content];
    _sharerLabel.text = shareContent;
    
    // 文字背景Layer
    if (!_sharerNickNameLayer) {
        _sharerNickNameLayer = [CAShapeLayer layer];
        _sharerNickNameLayer.fillColor = UIColorByHex(0xe4e8e9).CGColor;
        _sharerNickNameLayer.strokeColor = UIColorByHex(0xd6dadb).CGColor;
        _sharerNickNameLayer.lineWidth = 0.5f;
        [_sharerInfoView.layer insertSublayer:_sharerNickNameLayer atIndex:0];
    }
    
    NSDictionary *attribute = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f]};
    CGRect rect = [sharerString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 24.0f) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-2.0f, -3.0f, (rect.size.width + 4.0f), 24.0f) cornerRadius:10.0f];
    _sharerNickNameLayer.path = path.CGPath;
    
    // 文字渲染
    NSDictionary *linkAttributes = @{(__bridge id)kCTUnderlineStyleAttributeName: [NSNumber numberWithInt:kCTUnderlineStyleNone],
                                    (__bridge id)kCTForegroundColorAttributeName: [UIColor blackColor],
                                               (__bridge id)kCTFontAttributeName: [UIFont systemFontOfSize:14.0f]};
    _sharerLabel.activeLinkAttributes = linkAttributes;
    _sharerLabel.linkAttributes = linkAttributes;
    [_sharerLabel addLinkToPhoneNumber:sharer withRange:[shareContent rangeOfString:sharer]];
}

#pragma mark - HXDiscoveryCoverDelegate Methods
- (void)cover:(HXDiscoveryCover *)cover takeAcion:(HXDiscoveryCoverAction)action {
    HXDiscoveryCardViewAction cardAction = HXDiscoveryCardViewActionPlay;
    switch (action) {
        case HXDiscoveryCoverActionPlay: {
            break;
        }
        case HXDiscoveryCoverActionShowSharer: {
            cardAction = HXDiscoveryCardViewActionShowSharer;
            break;
        }
        case HXDiscoveryCoverActionShowInfecter: {
            cardAction = HXDiscoveryCardViewActionShowInfecter;
            break;
        }
        case HXDiscoveryCoverActionShowDetail: {
            cardAction = HXDiscoveryCardViewActionShowDetailOnly;
            break;
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(cardView:takeAction:)]) {
        [_delegate cardView:self takeAction:cardAction];
    }
}

#pragma mark - TTTAttributedLabelDelegate Methdos
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    if (_delegate && [_delegate respondsToSelector:@selector(cardView:takeAction:)]) {
        [_delegate cardView:self takeAction:HXDiscoveryCardViewActionShowSharer];
    }
}

#pragma mark - HXInfectViewDelegate Methods
- (void)infectView:(HXInfectView *)infectView takeAction:(HXInfectViewAction)action {
    switch (action) {
        case HXInfectViewActionInfect: {
            if (_delegate && [_delegate respondsToSelector:@selector(cardView:takeAction:)]) {
                [_delegate cardView:self takeAction:HXDiscoveryCardViewActionInfect];
            }
            break;
        }
        case HXInfectViewActionLayout: {
            break;
        }
    }
}

- (void)infectViewInfecterTaped:(HXInfectView *)infectView atIndex:(NSInteger)index {
    [self showDetailAction];
}

@end
