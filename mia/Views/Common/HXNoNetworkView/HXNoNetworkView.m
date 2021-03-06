//
//  HXNoNetworkView.m
//  mia
//
//  Created by miaios on 15/10/19.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import "HXNoNetworkView.h"
#import "AppDelegate.h"
#import "FavoriteMgr.h"

typedef void(^BLOCK)(void);

@interface HXNoNetworkView () {
    BLOCK _showBlock;
    BLOCK _playBlock;
}

@property (weak, nonatomic) IBOutlet  UILabel *playPrePromptLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation HXNoNetworkView

#pragma mark - Init Methods
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self viewConfigure];
}

#pragma mark - Config Methods
- (void)viewConfigure {
    _playButton.layer.cornerRadius = _playButton.frame.size.height/2;
//    _playButton.hidden = ![[FavoriteMgr standard] cachedCount];
	// TODO 1.3先把这个屏蔽了
	// 因为Profile页面点击进去还有分享等信息，下个版本页面结构调整后再打开
	// 受影响的是完全没有网络的情况，有3G的情况下还是可以播放收藏的歌曲的
	_playButton.hidden = YES;
    _playPrePromptLabel.hidden = _playButton.hidden;
}

#pragma mark - Event Response
- (IBAction)playButtonPressed {
    [self hidden];
    if (_playBlock) {
        _playBlock();
    }
}

#pragma mark - Public Methods
+ (instancetype)showOnViewController:(UIViewController *)viewController show:(void(^)(void))showBlock play:(void(^)(void))playBlock {
    HXNoNetworkView *view = [[[NSBundle mainBundle] loadNibNamed:@"HXNoNetworkView" owner:self options:nil] firstObject];
    [view showOnViewController:viewController show:showBlock play:playBlock];
    return view;
}

+ (void)hidden {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    UIWindow *mainWindow = delegate.window;
    NSArray *subviews = mainWindow.subviews;
    for (UIView *view in subviews) {
        if ([view isKindOfClass:[HXNoNetworkView class]]) {
            [view removeFromSuperview];
            break;
        }
    }
}

- (void)showOnViewController:(UIViewController *)viewController show:(void(^)(void))showBlock play:(void(^)(void))playBlock {
    [viewController.navigationController popToRootViewControllerAnimated:NO];
    _showBlock = showBlock;
    _playBlock = playBlock;
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    UIWindow *mainWindow = delegate.window;
    self.frame = mainWindow.frame;
    [mainWindow addSubview:self];
}

- (void)hidden {
    [self removeFromSuperview];
}

@end
