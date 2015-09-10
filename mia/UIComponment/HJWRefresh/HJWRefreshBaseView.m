//
//  HJWRefreshBaseView.m
//  huanjuwan
//
//  Created by huanjuwan on 14-8-6.
//  Copyright (c) 2014年 duowan. All rights reserved.
//

#import "HJWRefreshBaseView.h"
#import "UIView+Extension.h"
#import "UIScrollView+Extension.h"
#import <objc/message.h>

@interface HJWRefreshBaseView(){
    __weak UILabel *_statusLabel;
    __weak UIImageView *_arrowImage;
    __weak UIActivityIndicatorView *_activityView;
}

@end

@implementation HJWRefreshBaseView

NSString *const HJWRefreshContentOffset             = @"contentOffset";
static const CGFloat HJWRefreshViewHeight           = 64.0;

/**
 *  状态标签
 */
- (UILabel *)statusLabel
{
    if (!_statusLabel) {
        UILabel *statusLabel = [[UILabel alloc] init];
        statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        statusLabel.font = [UIFont boldSystemFontOfSize:13];
        statusLabel.textColor = [UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_statusLabel = statusLabel];
    }
    return _statusLabel;
}

/**
 *  箭头图片
 */
- (UIImageView *)arrowImage
{
    if (!_arrowImage) {
        UIImageView *arrowImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.png"]];
        arrowImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_arrowImage = arrowImage];
    }
    return _arrowImage;
}

/**
 *  状态标签
 */
- (UIActivityIndicatorView *)activityView
{
    if (!_activityView) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityView.bounds = self.arrowImage.bounds;
        activityView.autoresizingMask = self.arrowImage.autoresizingMask;
        [self addSubview:_activityView = activityView];
    }
    return _activityView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size.height = HJWRefreshViewHeight;
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor clearColor];

        self.state = HJWRefreshStateNormal;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 1.箭头
    CGFloat arrowX = self.width * 0.5 - 100;
    self.arrowImage.center = CGPointMake(arrowX, self.height * 0.5);
    
    // 2.指示器
    self.activityView.center = self.arrowImage.center;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    // 旧的父控件
    [self.superview removeObserver:self forKeyPath:HJWRefreshContentOffset context:nil];
    
    if (newSuperview) { // 新的父控件
        [newSuperview addObserver:self forKeyPath:HJWRefreshContentOffset options:NSKeyValueObservingOptionNew context:nil];
        
        // 设置宽度
        self.width = newSuperview.width;
        // 设置位置
        self.x = 0;
        
        // 记录UIScrollView
        _scrollView = (UIScrollView *)newSuperview;
        // 记录UIScrollView最开始的contentInset
        _scrollViewOriginalInset = _scrollView.contentInset;
    }
}

- (void)drawRect:(CGRect)rect
{
    if (self.state == HJWRefreshStateWillRefreshing) {
        self.state = HJWRefreshStateRefreshing;
    }
}

/**
 *  是否正在刷新
 *
 */
- (BOOL)isRefreshing
{
    return HJWRefreshStateRefreshing == self.state;
}

/**
 *  开始刷新
 */
- (void)beginRefreshing
{
    if (self.window) {
        self.state = HJWRefreshStateRefreshing;
    } else {
        _state = HJWRefreshStateWillRefreshing;
        [super setNeedsDisplay];
    }
}

/**
 *  结束刷新
 */
- (void)endRefreshing
{
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.state = HJWRefreshStateNormal;
    });
}

/**
 *  设置状态
 *
 */
- (void)setState:(HJWRefreshState )state
{
    // 0.存储当前的contentInset
    if (self.state != HJWRefreshStateRefreshing) {
        _scrollViewOriginalInset = self.scrollView.contentInset;
    }
    
    if (self.state == state)
        return;
    
    switch (state) {
		case HJWRefreshStateNormal: // 普通状态
        {
            // 显示箭头
            self.arrowImage.hidden = NO;
            
            // 停止转圈圈
            [self.activityView stopAnimating];
			break;
        }
            
        case HJWRefreshStatePulling:
            break;
            
		case HJWRefreshStateRefreshing:
        {
            // 开始转圈圈
			[self.activityView startAnimating];
            // 隐藏箭头
			self.arrowImage.hidden = YES;
            
            // 回调
            if ([self.beginRefreshingTaget respondsToSelector:self.beginRefreshingAction]) {
                objc_msgSend(self.beginRefreshingTaget, self.beginRefreshingAction, self);
            }
            
            if (self.beginRefreshingCallback) {
                self.beginRefreshingCallback();
            }
			break;
        }
        default:
            break;
	}
    
    _state = state;
}

@end








