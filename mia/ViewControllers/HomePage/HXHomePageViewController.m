//
//  HXHomePageViewController.m
//  mia
//
//  Created by miaios on 15/10/9.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import "HXHomePageViewController.h"
#import "HXRadioViewController.h"
#import "HXBubbleView.h"
#import "HXHomePageWaveView.h"
#import "HXInfectUserView.h"
#import "UserSession.h"
#import "LoginViewController.h"
#import "MyProfileViewController.h"
#import "HXShareViewController.h"
#import "WebSocketMgr.h"
#import "NSString+IsNull.h"
#import "UIButton+WebCache.h"
#import "MiaAPIHelper.h"
#import "UserDefaultsUtils.h"
#import "HXNoNetworkView.h"
#import "InfectUserItem.h"
#import "UIImageView+WebCache.h"
#import "LocationMgr.h"
#import "HXAlertBanner.h"
#import "HXGuideView.h"
#import "HXVersion.h"
#import "HXMusicDetailViewController.h"
#import "UIImage+ColorToImage.h"
#import "GuestProfileViewController.h"
#import "ShareItem.h"
#import "UpdateHelper.h"
#import "FavoriteMgr.h"
#import "HXNavigationController.h"
#import "HXInfectUserItemView.h"

static NSString *kAlertMsgNoNetwork     = @"没有网络连接，请稍候重试";
static NSString *kGuideViewShowKey      = @"kGuideViewShow-v";

@interface HXHomePageViewController () <LoginViewControllerDelegate, HXBubbleViewDelegate , MyProfileViewControllerDelegate , HXRadioViewControllerDelegate> {
    BOOL _toLogin;
    BOOL _animating;                // 动画执行标识
    CGFloat _fishViewCenterY;       // 小鱼中心高度位置
    NSTimer *_timer;                // 定时器，用户在妙推动作时默认不评论定时执行结束动画
    ShareItem *_playItem;

}

@end

@implementation HXHomePageViewController

#pragma mark - View Controller Life Cycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:_toLogin animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initConfig];
    [self viewConfig];
    
    if ([self needShowGuideView]) {
        __weak __typeof__(self)weakSelf = self;
        [HXGuideView showGuide:^{
            __strong __typeof__(self)strongSelf = weakSelf;
            [strongSelf startLoadMusic];
            [strongSelf guideViewShowed];
        }];
    } else {
        [self startLoadMusic];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _fishViewCenterY = _fishView.center.y;      // 记录小鱼中心点高度，用于控制小鱼拖动
}

- (void)dealloc {
    // 通知关闭
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidOpen object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidFailWithError object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidAutoReconnectFailed object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationPushUnread object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidCloseWithCode object:nil];

	[[UserSession standard] removeObserver:self forKeyPath:UserSessionKey_Avatar context:nil];
}

#pragma mark - Prepare
static NSString *HomePageContainerIdentifier = @"HomePageContainerIdentifier";
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:HomePageContainerIdentifier]) {
        _radioViewController = segue.destinationViewController;
		_radioViewController.delegate = self;
    }
}

#pragma mark - Config Methods
- (void)initConfig {
    kGuideViewShowKey = [kGuideViewShowKey stringByAppendingFormat:@"%@.%@", [HXVersion appVersion], [HXVersion appBuildVersion]];
    // 通知注册
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidOpen:) name:WebSocketMgrNotificationDidOpen object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidFailWithError:) name:WebSocketMgrNotificationDidFailWithError object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidAutoReconnectFailed:) name:WebSocketMgrNotificationDidAutoReconnectFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketPushUnread:) name:WebSocketMgrNotificationPushUnread object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidCloseWithCode:) name:WebSocketMgrNotificationDidCloseWithCode object:nil];
	[[UserSession standard] addObserver:self forKeyPath:UserSessionKey_Avatar options:NSKeyValueObservingOptionNew context:nil];

    // 初始化小鱼动画帧
    NSMutableArray *fishIcons = @[].mutableCopy;
    for (NSInteger index = 1; index <= 67; index ++) {
        [fishIcons addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%zd", index]]];
    }
    _fishView.animationImages = fishIcons;
    _fishView.animationDuration = 3.0f;         //设置小鱼动画为20帧左右
    
    // 处理手势响应先后顺序
    [_swipeGesture requireGestureRecognizerToFail:_panGesture];
}

- (void)viewConfig {
    _shareButton.backgroundColor = [UIColor whiteColor];
    _profileButton.layer.borderWidth = 0.5f;
    _profileButton.layer.borderColor = UIColorFromHex(@"A2A2A2", 1.0f).CGColor;
    _profileButton.layer.cornerRadius = _profileButton.frame.size.height/2;
    
    _shareButton.backgroundColor = [UIColor whiteColor];
    _shareButton.layer.cornerRadius = _profileButton.frame.size.height/2;
    
    _pushPromptLabel.alpha = 0.0f;
    
    [self hanleUnderiPhone6Size];
    [self animationViewConfig];
}

- (void)hanleUnderiPhone6Size {
    if ([HXVersion isIPhone5SPrior]) {
        _fishBottomConstraint.constant = _fishBottomConstraint.constant - 5.0f;
    }
}

- (void)animationViewConfig {
    // 配置气泡的比例和放大锚点；配置妙推用户视图的缩放比例
    _bubbleView.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
    _bubbleView.layer.anchorPoint = CGPointMake(0.4f, 1.0f);
    _infectUserView.transform = CGAffineTransformMakeScale(0.84f, 0.84f);
    
    // 配置提示条，设置为隐藏
    _infectCountPromptLabel.alpha = 0.0f;
}

- (void)initLocationMgr {
	[[LocationMgr standard] initLocationMgr];
	[[LocationMgr standard] startUpdatingLocationWithOnceBlock:nil];
}

#pragma mark - Notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	//	NSLog(@"keyPath = %@, change = %@, context = %s", keyPath, change, (char *)context);
	if ([keyPath isEqualToString:UserSessionKey_Avatar]) {
		NSString *newAvatarUrl = change[NSKeyValueChangeNewKey];
		if ([NSString isNull:newAvatarUrl]) {
			[_profileButton setImage:[UIImage imageNamed:@"HP-InfectUserDefaultHeader"] forState:UIControlStateNormal];
        } else {
			int unreadCount = [[[UserSession standard] unreadCommCnt] intValue];
			[self updateProfileButtonWithUnreadCount:unreadCount];
		}
	}
}

- (void)notificationWebSocketDidOpen:(NSNotification *)notification {
	[HXNoNetworkView hidden];
	[MiaAPIHelper sendUUIDWithCompleteBlock:^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
		if (success) {
			[self checkUpdate];
			if (![self autoLogin]) {
				[_radioViewController loadShareList];
				//[_radioView checkIsNeedToGetNewItems];
			}
		} else {
			[self autoReconnect];
		}
	} timeoutBlock:^(MiaRequestItem *requestItem) {
		[self autoReconnect];
	}];
}

- (void)notificationWebSocketDidFailWithError:(NSNotification *)notification {
	// TODO auto reconnect
	static NSString * kAlertMsgWebSocketFailed = @"服务器不稳定，重连中";
	[HXAlertBanner showWithMessage:kAlertMsgWebSocketFailed tap:nil];
}

- (void)notificationWebSocketDidAutoReconnectFailed:(NSNotification *)notification {
	[self showNoNetworkView];
}

- (void)notificationWebSocketPushUnread:(NSNotification *)notification {
	id ret = [notification userInfo][MiaAPIKey_Values][MiaAPIKey_Return];
	if (0 == [ret intValue]) {
		[self updateProfileButtonWithUnreadCount:[[notification userInfo][MiaAPIKey_Values][@"num"] intValue]];
	} else {
		NSLog(@"unread comment failed! error:%@", [notification userInfo][MiaAPIKey_Values][MiaAPIKey_Error]);
	}
}

- (void)notificationWebSocketDidCloseWithCode:(NSNotification *)notification {
	NSLog(@"Connection Closed! (see logs)");
}

#pragma mark - Event Response
- (IBAction)profileButtonPressed {
    // 用户按钮点击事件，未登录显示登录页面，已登录显示用户信息页面
    if ([[UserSession standard] isLogined]) {
        MyProfileViewController *myProfileViewController = [[MyProfileViewController alloc] initWitUID:[[UserSession standard] uid]
                                                                                              nickName:[[UserSession standard] nick]];
        myProfileViewController.customDelegate = self;
        [self.navigationController pushViewController:myProfileViewController animated:YES];
	} else {
        [self presentLoginViewController:nil];
    }
}

- (IBAction)shareButtonPressed {
    // 音乐分享按钮点击事件，未登录显示登录页面，已登录显示音乐分享页面
    if ([[UserSession standard] isLogined]) {
        HXShareViewController *shareViewController = [HXShareViewController instance];
        [self.navigationController pushViewController:shareViewController animated:YES];
    } else {
        [self presentLoginViewController:nil];
    }
}

- (IBAction)tapGesture {
    [self.view endEditing:YES];
    if (_animating) {
        if (![[UserSession standard] isLogined]) {
            [self cancelLoginOperate];
        } else {
            [self startFinishedAnimation];
        }
    } else {
        [self stopAnimation];
        HXMusicDetailViewController *musicDetailViewController = [[UIStoryboard storyboardWithName:@"MusicDetail" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([HXMusicDetailViewController class])];
        musicDetailViewController.playItem = _playItem;
        [self.navigationController pushViewController:musicDetailViewController animated:YES];
    }
}

static CGFloat OffsetHeightThreshold = 160.0f;  // 用户拖动手势触发动画阀值
- (IBAction)gestureEvent:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        // 拖动手势
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
        switch (panGesture.state) {
            // 1.手势开始，小鱼游动
            case UIGestureRecognizerStateBegan: {
                [_fishView startAnimating];
                break;
            }
            // 拖动手势位移，配合拖动阀值移动小鱼并出发动画
            case UIGestureRecognizerStateChanged: {
                if (!_playItem.isInfected) {
                    CGFloat offsetHeight = [panGesture translationInView:self.view].y;
                    if (offsetHeight < 0.0f) {
                        CGFloat fabsOffsetHeightY = fabs(offsetHeight);
                        if (fabsOffsetHeightY >= OffsetHeightThreshold) {
                            [self startAnimation];
                        } else {
                            CGFloat panPercent = (fabsOffsetHeightY/OffsetHeightThreshold);
                            _fishView.center = CGPointMake(_fishView.center.x, _fishViewCenterY - 30.0f*panPercent);
                        }
                    }
                }
                break;
            }
            // 手势结束，失败，取消，停止小鱼游动，小鱼弹回，用于用户取消操作
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled: {
                if (!_playItem.isInfected) {
                    if (!_animating) {
                        [_fishView stopAnimating];
                        __weak __typeof__(self)weakSelf = self;
                        [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
                            __strong __typeof__(self)strongSelf = weakSelf;
                            strongSelf.fishView.center = CGPointMake(strongSelf.fishView.center.x, _fishViewCenterY);
                        } completion:nil];
                    }
                }
                break;
            }
                
            default:
                break;
        }
    } else if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]]) {
        // 滑动手势
        UISwipeGestureRecognizer *swipeGesture = (UISwipeGestureRecognizer *)gesture;
        switch (swipeGesture.direction) {
            case UISwipeGestureRecognizerDirectionUp: {
                if (!_playItem.isInfected) {
                    [self startAnimation];
                }
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Private Methods
- (BOOL)needShowGuideView {
    NSNumber *showed = [[NSUserDefaults standardUserDefaults] valueForKey:kGuideViewShowKey];
    return !showed.boolValue;
}

- (void)guideViewShowed {
    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:kGuideViewShowKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)startLoadMusic {
    [[WebSocketMgr standard] watchNetworkStatus];
    [self initLocationMgr];
}

- (void)startAnimation {
    if (!_animating) {
        _animating = YES;
        if ([[UserSession standard] isLogined]) {
            [self infectShare];
        }
        [self startWaveAnimation];
        [self startPopFishAnimation];
    }
}

- (void)stopAnimation {
    _animating = NO;
}

- (void)showInfectUsers:(NSArray *)infectUsers {
    [_infectUserView removeAllItem];
    NSInteger infectUserCount = infectUsers.count;
    if (infectUserCount) {
        NSMutableArray *itmes = [NSMutableArray arrayWithCapacity:infectUsers.count];
        for (InfectUserItem *item in infectUsers) {
            [itmes addObject:[NSURL URLWithString:item.avatar]];
        }
        [_infectUserView showWithItems:itmes];
        __weak __typeof__(self)weakSelf = self;
        [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            __strong __typeof__(self)strongSelf = weakSelf;
            [strongSelf.infectUserView refresh];
        } completion:^(BOOL finished) {
            __strong __typeof__(self)strongSelf = weakSelf;
            // 妙推用户头像跳动动画
            [strongSelf.infectUserView refreshItemWithAnimation];
        }];
    }
    
    [self showPushPromptLabel:!infectUserCount];
}

- (void)showPushPromptLabel:(BOOL)show {
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.4f animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.pushPromptLabel.alpha = show ? 1.0f : 0.0f;
    }];
}

- (void)addPushUserHeader {
    [self updatePromptLabel];
    // 妙推用户头像添加以及动画
    [_infectUserView addItemAtFirstIndex:[NSURL URLWithString:[[UserSession standard] avatar]]];
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        [strongSelf.infectUserView refresh];
    } completion:^(BOOL finished) {
        __strong __typeof__(self)strongSelf = weakSelf;
        // 妙推用户头像跳动动画
        [strongSelf.infectUserView refreshItemWithAnimation];
        // 妙推提示条显示动画
        [strongSelf startPushPromptLabelAnimation];
    }];
}

- (void)updatePromptLabel {
    NSInteger count = _playItem.infectTotal;
    NSString *prompt = [NSString stringWithFormat:@"%@人%@妙推", @(count), ((count > 5) ? @"等" : @"")];
    _infectCountPromptLabel.text = prompt;
}

- (void)reset {
    [_fishView stopAnimating];
    [_bubbleView reset];
    [_waveView reset];
    
    // 重新布局
    _fishBottomConstraint.constant = [HXVersion isIPhone5SPrior] ? 15.0f : 20.0f;
    _headerViewBottomConstraint.constant = 2.0f;
    _fishView.alpha = 1.0f;
    _bubbleView.alpha = 1.0f;
    [self animationViewConfig];
    _fishView.transform = CGAffineTransformIdentity;
    [self.view layoutIfNeeded];
}

- (void)executeTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:2.4f target:self selector:@selector(startFinishedAnimation) userInfo:nil repeats:NO];
}

- (void)startPushMusicRequsetWithComment:(NSString *)comment {
    comment = comment ?: @"";
    // 用户按钮点击事件，未登录显示登录页面，已登录显示用户信息页面
    if ([[UserSession standard] isLogined]) {
        [MiaAPIHelper postCommentWithShareID:_playItem.sID
                                     comment:comment
                               completeBlock:
		 ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
			 if (success) {
				 [HXAlertBanner showWithMessage:@"评论成功" tap:nil];
			 } else {
				 id error = userInfo[MiaAPIKey_Values][MiaAPIKey_Error];
				 [HXAlertBanner showWithMessage:[NSString stringWithFormat:@"%@", error] tap:nil];
			 }
		 } timeoutBlock:^(MiaRequestItem *requestItem) {
			 [HXAlertBanner showWithMessage:@"提交评论失败，网络请求超时" tap:nil];
		 }];
		[self startFinishedAnimation];
    } else {
        [self presentLoginViewController:nil];
    }
}

- (void)updateProfileButtonWithUnreadCount:(int)unreadCommentCount {
    if (unreadCommentCount <= 0) {
        _profileButton.layer.borderWidth = 0.5f;
        [_profileButton sd_setImageWithURL:[NSURL URLWithString:[[UserSession standard] avatar]]
                                  forState:UIControlStateNormal
                          placeholderImage:[UIImage imageNamed:@"HP-InfectUserDefaultHeader"]];
	} else {
        _profileButton.layer.borderWidth = 0.0f;
		[_profileButton setImage:nil forState:UIControlStateNormal];
		[_profileButton setBackgroundColor:UIColorFromHex(@"0BDEBC", 1.0)];
		[_profileButton setTitle:[NSString stringWithFormat:@"%d", unreadCommentCount] forState:UIControlStateNormal];
	}
}

- (void)checkUpdate {
	UpdateHelper *aUpdateHelper = [[UpdateHelper alloc] init];
	[aUpdateHelper checkNow];
}

- (BOOL)autoLogin {
	NSString *userName = [UserDefaultsUtils valueWithKey:UserDefaultsKey_UserName];
	NSString *passwordHash = [UserDefaultsUtils valueWithKey:UserDefaultsKey_PasswordHash];
	if ([NSString isNull:userName] || [NSString isNull:passwordHash]) {
		return NO;
	}
    
    [MiaAPIHelper loginWithPhoneNum:userName
                       passwordHash:passwordHash
                      completeBlock:
     ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
         if (success) {
             [[UserSession standard] setUid:userInfo[MiaAPIKey_Values][@"uid"]];
             [[UserSession standard] setNick:userInfo[MiaAPIKey_Values][@"nick"]];
             [[UserSession standard] setUtype:userInfo[MiaAPIKey_Values][@"utype"]];
             [[UserSession standard] setUnreadCommCnt:userInfo[MiaAPIKey_Values][@"unreadCommCnt"]];

             NSString *avatarUrl = userInfo[MiaAPIKey_Values][@"userpic"];
             NSString *avatarUrlWithTime = [NSString stringWithFormat:@"%@?t=%ld", avatarUrl, (long)[[NSDate date] timeIntervalSince1970]];
             [[UserSession standard] setAvatar:avatarUrlWithTime];
             [UserDefaultsUtils saveValue:userInfo[MiaAPIKey_Values][@"uid"] forKey:UserDefaultsKey_UID];
             [UserDefaultsUtils saveValue:userInfo[MiaAPIKey_Values][@"nick"] forKey:UserDefaultsKey_Nick];
         }
         
         [_radioViewController loadShareList];
     } timeoutBlock:^(MiaRequestItem *requestItem) {
         NSLog(@"audo login timeout!");
         [_radioViewController loadShareList];
     }];
	return YES;
}

- (void)autoReconnect {
	// TODO auto reconnect
	[[WebSocketMgr standard] reconnect];
}

- (void)infectShare {
    if (!_playItem.isInfected) {
        _playItem.isInfected = YES;
        _playItem.infectTotal += 1;
        __weak __typeof__(self)weakSelf = self;
        // 传播出去不需要切换歌曲，需要记录下传播的状态和上报服务器
        [MiaAPIHelper InfectMusicWithLatitude:[[LocationMgr standard] currentCoordinate].latitude
                                    longitude:[[LocationMgr standard] currentCoordinate].longitude
                                      address:[[LocationMgr standard] currentAddress]
                                         spID:_playItem.spID
                                completeBlock:
         ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
             if (success) {
                 __strong __typeof__(self)strongSelf = weakSelf;

				 int isInfected = [userInfo[MiaAPIKey_Values][@"data"][@"isInfected"] intValue];
				 int infectTotal = [userInfo[MiaAPIKey_Values][@"data"][@"infectTotal"] intValue];
				 NSArray *infectArray = userInfo[MiaAPIKey_Values][@"data"][@"infectList"];
				 NSString *spID = [userInfo[MiaAPIKey_Values][@"data"][@"spID"] stringValue];

				 if ([spID isEqualToString:strongSelf->_playItem.spID]) {
					 strongSelf->_playItem.infectTotal = infectTotal;
					 [strongSelf->_playItem parseInfectUsersFromJsonArray:infectArray];
					 strongSelf->_playItem.isInfected = isInfected;
				 }
             } else {
                 id error = userInfo[MiaAPIKey_Values][MiaAPIKey_Error];
                 [HXAlertBanner showWithMessage:[NSString stringWithFormat:@"%@", error] tap:nil];
             }
         } timeoutBlock:^(MiaRequestItem *requestItem) {
             __strong __typeof__(self)strongSelf = weakSelf;
             strongSelf->_playItem.isInfected = YES;
             [HXAlertBanner showWithMessage:@"妙推失败，网络请求超时" tap:nil];
         }];
    }
}

- (void)showOfflineProfileWithPlayFavorite:(BOOL)playFavorite {
    if ([[UserSession standard] isCachedLogin]) {
        MyProfileViewController *myProfileViewController = [[MyProfileViewController alloc] initWitUID:[[UserSession standard] uid]
                                                                                              nickName:[[UserSession standard] nick]];
        myProfileViewController.customDelegate = self;
        myProfileViewController.playFavoriteOnceTime = playFavorite;
        [self.navigationController pushViewController:myProfileViewController animated:playFavorite ? NO : YES];
    } else {
        [self presentLoginViewController:nil];
	}
}

- (void)showNoNetworkView {
	[HXNoNetworkView showOnViewController:self show:^{
		[self showOfflineProfileWithPlayFavorite:NO];
	} play:^{
		[self showOfflineProfileWithPlayFavorite:YES];
	}];
}

- (void)cancelLoginOperate {
    [self startWaveMoveUpAnimation];
    [self startHeaderViewPopBackAnimation];
    [self startFinshAndBubbleHiddenAnimation];
}

- (void)displayWithInfectState:(BOOL)infected {
    _infectCountPromptLabel.alpha = 0.0f;
    _bubbleView.hidden = infected;
    _fishView.hidden = infected;
    
    if (infected) {
        [self startInfectedStateAnimation];
    } else {
        [self startUnInfectedStateAnimation];
    }
}

- (void)presentLoginViewController:(void(^)(BOOL success))success {
    _toLogin = YES;
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    loginViewController.loginViewControllerDelegate = self;
    [loginViewController loginSuccess:success];
    HXNavigationController *loginNavigationViewController = [[HXNavigationController alloc] initWithRootViewController:loginViewController];
    __weak __typeof__(self)weakSelf = self;
    [self presentViewController:loginNavigationViewController animated:YES completion:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf->_toLogin = NO;
    }];
}

#pragma mark - Animation
- (void)startWaveAnimation {
    [_waveView.waveView startAnimating];
}

- (void)stopWaveAnimation {
    [_waveView.waveView stopAnimating];
}

// 小鱼跳出动画
- (void)startPopFishAnimation {
    _fishBottomConstraint.constant = self.view.frame.size.height/2 - ([HXVersion isIPhone5SPrior] ? 110.0f : 140.0f);
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.fishView.transform = CGAffineTransformIdentity;
        [strongSelf.view layoutIfNeeded];
    } completion:nil];
    
    [self startBubbleScaleAnimation];
    [self startWaveMoveDownAnimation];
    [self startHeaderViewPopAnimationAddUser:YES];
}

// 气泡弹出动画
- (void)startBubbleScaleAnimation {
    [_bubbleView showWithLogin:[[UserSession standard] isLogined]];
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.5f delay:0.1f usingSpringWithDamping:0.7f initialSpringVelocity:1.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.bubbleView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        if ([[UserSession standard] isLogined]) {
            __strong __typeof__(self)strongSelf = weakSelf;
            [strongSelf executeTimer];
        }
    }];
}

// 波浪退出动画
- (void)startWaveMoveDownAnimation {
    [_waveView waveMoveDownAnimation:nil];
}

// 波浪升起动画
- (void)startWaveMoveUpAnimation {
    __weak __typeof__(self)weakSelf = self;
    [_waveView waveMoveUpAnimation:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        [strongSelf reset];
    }];
}

- (void)startFinshAndBubbleHiddenAnimation {
    [_fishView stopAnimating];
    
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.4f animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.fishView.alpha = 0.0f;
        strongSelf.bubbleView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf->_animating = NO;
        strongSelf.fishBottomConstraint.constant = 20.0f;
    }];
}

// 头像弹出动画
- (void)startHeaderViewPopAnimationAddUser:(BOOL)add {
    _headerViewBottomConstraint.constant = 40.0f;
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:1.0f delay:0.4f usingSpringWithDamping:0.5f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.infectUserView.transform = CGAffineTransformIdentity;
        [strongSelf.infectUserView layoutIfNeeded];
    } completion:^(BOOL finished) {
        __strong __typeof__(self)strongSelf = weakSelf;
        if (!add) {
            [strongSelf updatePromptLabel];
            [strongSelf startPushPromptLabelAnimation];
        }
    }];
    if ([[UserSession standard] isLogined] && add) {
        [self addPushUserHeader];
    }
}

- (void)startPushPromptLabelAnimation {
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.3f animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.infectCountPromptLabel.alpha = 1.0f;
    } completion:nil];
}

// 头像收回动画
- (void)startHeaderViewPopBackAnimation {
    _headerViewBottomConstraint.constant = 2.0f;
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:1.0f delay:0.0f usingSpringWithDamping:0.5f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        strongSelf.infectUserView.transform = CGAffineTransformMakeScale(0.84f, 0.84f);
        [strongSelf.infectUserView layoutIfNeeded];
    } completion:^(BOOL finished) {
        __strong __typeof__(self)strongSelf = weakSelf;
        if (strongSelf->_animating) {
            [strongSelf stopAnimation];
        }
    }];
}

// 妙推完成，结束动画
- (void)startFinishedAnimation {
    __weak __typeof__(self)weakSelf = self;
    [UIView animateWithDuration:0.8f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        __strong __typeof__(self)strongSelf = weakSelf;
        
        // 小鱼转动动画
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, 0.2f, 0.2f);
        transform = CGAffineTransformRotate(transform, -M_PI * 3/4);
        strongSelf.fishView.transform = transform;
        strongSelf.fishView.alpha = 0.0f;
        
        // 气泡缩小动画
        strongSelf.bubbleView.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
        strongSelf.bubbleView.alpha = 0.0f;
        
        // 小鱼，气泡移动结束动画
        UIView *header = strongSelf.infectUserView.stacView.arrangedSubviews.firstObject;
        CGPoint endPont = CGPointMake(strongSelf.infectUserView.frame.origin.x +  header.center.x, strongSelf.infectUserView.frame.origin.y);
        strongSelf.fishView.center = endPont;
        strongSelf.bubbleView.center = endPont;
    } completion:^(BOOL finished) {
        __strong __typeof__(self)strongSelf = weakSelf;
        [strongSelf stopAnimation];
    }];
}

- (void)startInfectedStateAnimation {
    [self startWaveMoveDownAnimation];
    [self startHeaderViewPopAnimationAddUser:NO];
}

- (void)startUnInfectedStateAnimation {
    [self startWaveMoveUpAnimation];
    [self startHeaderViewPopBackAnimation];
}

#pragma mark - HXBubbleViewDelegate Methods
- (void)bubbleViewStartEdit:(HXBubbleView *)bubbleView {
    // 产品设计内容，用于一旦编辑气泡内容，必须关闭小鱼洄游动画定时器
    [_timer invalidate];
}

- (void)bubbleView:(HXBubbleView *)bubbleView shouldSendComment:(NSString *)comment {
    // 用户触发妙推评论发送之后关闭键盘并执行妙推评论数据请求
    [self.view endEditing:YES];
    [self startPushMusicRequsetWithComment:comment];
}

- (void)bubbleViewShouldLogin:(HXBubbleView *)bubbleView {
    [self presentLoginViewController:nil];
    [self cancelLoginOperate];
}

#pragma mark - Login View Controller Delegate Methods
- (void)loginViewControllerDidSuccess {
    if ([[UserSession standard] isLogined]) {
        int unreadCommentCount = [[[UserSession standard] unreadCommCnt] intValue];
        [self updateProfileButtonWithUnreadCount:unreadCommentCount];
    }
}

#pragma mark - MyProfileViewControllerDelegate Methods
- (void)myProfileViewControllerWillDismiss {
	if (![[WebSocketMgr standard] isOpen]) {
		[self showNoNetworkView];
	}
}

- (void)myProfileViewControllerUpdateUnreadCount:(int)count {
	[self updateProfileButtonWithUnreadCount:count];
}

#pragma mark - HXRadioViewControllerDelegate Methods
- (void)userWouldLikeSeeSharerHomePageWithItem:(ShareItem *)item {
	GuestProfileViewController *viewController = [[GuestProfileViewController alloc] initWitUID:item.uID nickName:item.sNick];
	[self.navigationController pushViewController:viewController animated:YES];
}

- (void)userStartNeedLogin {
    [self presentLoginViewController:^(BOOL success) {
        __weak __typeof__(self)weakSelf = self;
        [MiaAPIHelper favoriteMusicWithShareID:_playItem.sID
                                    isFavorite:!_playItem.favorite
                                 completeBlock:
         ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
             __strong __typeof__(self)strongSelf = weakSelf;
             if (success) {
                 id act = userInfo[MiaAPIKey_Values][@"act"];
                 id sID = userInfo[MiaAPIKey_Values][@"id"];
                 BOOL favorite = [act intValue];
                 if ([strongSelf->_playItem.sID integerValue] == [sID intValue]) {
                     strongSelf->_playItem.favorite = favorite;
                 }
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
    }];
}

- (void)shouldDisplayInfectUsers:(ShareItem *)item {
    _playItem = item;
    [self showInfectUsers:item.infectUsers];
    [self displayWithInfectState:item.isInfected];
}

- (void)musicDidChange:(ShareItem *)item {
//    _playItem = item;
//    [self displayWithInfectState:item.isInfected];
}

- (void)raidoViewDidTaped {
    [self tapGesture];
}

@end
