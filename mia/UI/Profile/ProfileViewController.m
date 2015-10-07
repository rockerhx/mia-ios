//
//  ProfileViewController.m
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "ProfileViewController.h"
#import "MIAButton.h"
#import "MIALabel.h"
#import "UIScrollView+MIARefresh.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Extrude.h"
#import "ProfileCollectionViewCell.h"
#import "ProfileHeaderView.h"
#import "MiaAPIHelper.h"
#import "WebSocketMgr.h"
#import "ProfileShareModel.h"
#import "FavoriteModel.h"
#import "DetailViewController.h"
#import "FavoriteViewController.h"
#import "MusicPlayerMgr.h"
#import "FavoriteItem.h"

static NSString * const kProfileCellReuseIdentifier 		= @"ProfileCellId";
static NSString * const kProfileBiggerCellReuseIdentifier 	= @"ProfileBiggerCellId";
static NSString * const kProfileHeaderReuseIdentifier 		= @"ProfileHeaderId";

static const CGFloat kProfileItemMarginH 	= 10;
static const CGFloat kProfileItemMarginV 	= 10;
static const CGFloat kProfileHeaderHeight 	= 240;

@interface ProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ProfileHeaderViewDelegate, FavoriteViewControllerDelegate>

@end

@implementation ProfileViewController {
	NSString 				*_uid;
	NSString 				*_nickName;
	BOOL 					_isMyProfile;
	BOOL 					_playingFavorite;

	long 					_currentPageStart;

	UICollectionView 		*_profileCollectionView;
	ProfileHeaderView 		*_profileHeaderView;
	FavoriteViewController	*_favoriteViewController;

	ProfileShareModel 		*_shareListModel;
	FavoriteModel 			*_favoriteModel;
}

- (id)initWitUID:(NSString *)uid nickName:(NSString *)nickName isMyProfile:(BOOL)isMyProfile {
	self = [super init];
	if (self) {
		_uid = uid;
		_nickName = nickName;
		_isMyProfile = isMyProfile;

		[self initUI];
		[self initData];
		[_profileCollectionView addFooterWithTarget:self action:@selector(requestShareList)];

		_favoriteViewController = [[FavoriteViewController alloc] initWitBackground:nil];
		_favoriteViewController.favoriteViewControllerDelegate = self;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidReceiveMessage:) name:WebSocketMgrNotificationDidReceiveMessage object:nil];
	}

	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidReceiveMessage object:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
	return NO;
}

- (void)initUI {
	self.title = _nickName;
	[self initBarButton];

	//1.初始化layout
	UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
	//设置collectionView滚动方向
	//    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
	//设置headerView的尺寸大小
	if (_isMyProfile) {
		layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, kProfileHeaderHeight);
	} else {
		layout.headerReferenceSize = CGSizeZero;
	}

	//该方法也可以设置itemSize
	CGFloat itemWidth = (self.view.frame.size.width - kProfileItemMarginH * 3) / 2;
	layout.itemSize =CGSizeMake(itemWidth, itemWidth);

	//2.初始化collectionView
	_profileCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
	[self.view addSubview:_profileCollectionView];
	_profileCollectionView.backgroundColor = [UIColor whiteColor];

	//3.注册collectionViewCell
	//注意，此处的ReuseIdentifier 必须和 cellForItemAtIndexPath 方法中 一致 均为 cellId
	[_profileCollectionView registerClass:[ProfileCollectionViewCell class] forCellWithReuseIdentifier:kProfileCellReuseIdentifier];
	[_profileCollectionView registerClass:[ProfileCollectionViewCell class] forCellWithReuseIdentifier:kProfileBiggerCellReuseIdentifier];

	//注册headerView  此处的ReuseIdentifier 必须和 cellForItemAtIndexPath 方法中 一致  均为reusableView
	[_profileCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kProfileHeaderReuseIdentifier];

	//4.设置代理
	_profileCollectionView.delegate = self;
	_profileCollectionView.dataSource = self;

	[self initHeaderView];
}

- (void)initBarButton {
	UIImage *backButtonImage = [UIImage imageNamed:@"back"];
	MIAButton *backButton = [[MIAButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, backButtonImage.size.width, backButtonImage.size.height)
												 titleString:nil
												  titleColor:nil
														font:nil
													 logoImg:nil
											 backgroundImage:backButtonImage];
	UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
	self.navigationItem.leftBarButtonItem = leftButton;
	[backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];

	if (_isMyProfile) {
		UIImage *settingButtonImage = [UIImage imageNamed:@"setting"];
		MIAButton *settingButton = [[MIAButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, settingButtonImage.size.width, settingButtonImage.size.height)
														titleString:nil
														 titleColor:nil
															   font:nil
															logoImg:nil
													backgroundImage:settingButtonImage];
		UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:settingButton];
		self.navigationItem.rightBarButtonItem = rightButton;
		[settingButton addTarget:self action:@selector(settingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	}
}

- (void)initHeaderView {
	_profileHeaderView = [[ProfileHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kProfileHeaderHeight)];
	_profileHeaderView.profileHeaderViewDelegate = self;
}

- (void)initData {
	_shareListModel = [[ProfileShareModel alloc] init];

	[self requestShareList];
	[self requestFavoriteList];

	_favoriteModel = [[FavoriteModel alloc] init];

	[self requestFavoriteList];
}

- (void)requestShareList {
	static const long kShareListPageCount = 10;

	++_currentPageStart;
	[MiaAPIHelper getShareListWithUID:_uid start:_currentPageStart item:kShareListPageCount];
//	// for test
//	[MiaAPIHelper getShareListWithUID:@"442" start:currentPageStart item:kShareListPageCount];
}

- (void)requestFavoriteList {
	static const long kFavoritePageItemCount	= 10;
	[MiaAPIHelper getFavoriteListWithStart:_favoriteModel.lastID item:kFavoritePageItemCount];
}

#pragma mark - delegate

#pragma mark collectionView代理方法

//返回section个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

//每个section的item个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return _shareListModel.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (!_isMyProfile && indexPath.row == 0) {
		ProfileCollectionViewCell *cell = (ProfileCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kProfileBiggerCellReuseIdentifier
																												 forIndexPath:indexPath];
		cell.isBiggerCell = YES;
		cell.isMyProfile = _isMyProfile;
		cell.shareItem = _shareListModel.dataSource[indexPath.row];
		return cell;
	} else {
		ProfileCollectionViewCell *cell = (ProfileCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kProfileCellReuseIdentifier

																												 forIndexPath:indexPath];
		cell.isBiggerCell = NO;
		cell.isMyProfile = _isMyProfile;
		cell.shareItem = _shareListModel.dataSource[indexPath.row];
		return cell;
	}
}

//设置每个item的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat itemWidth = (self.view.frame.size.width - kProfileItemMarginH * 3) / 2;

	// 如果是客人态的话，第一个cell显示成长方形
	if (!_isMyProfile && indexPath.row == 0) {
		return CGSizeMake(self.view.frame.size.width - 2 * kProfileItemMarginH, itemWidth);
	} else {
		return CGSizeMake(itemWidth, itemWidth);
	}
}

//footer的size
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
//{
//    return CGSizeMake(10, 10);
//}

//header的size
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
//{
//    return CGSizeMake(10, 10);
//}

//设置每个item的UIEdgeInsets
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(10, 10, 10, 10);
}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return kProfileItemMarginH;
}


//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return kProfileItemMarginV;
}


//通过设置SupplementaryViewOfKind 来设置头部或者底部的view，其中 ReuseIdentifier 的值必须和 注册是填写的一致，本例都为 “reusableView”
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if (!_isMyProfile)
		return nil;

	if ([kind isEqual:UICollectionElementKindSectionHeader]) {
		UICollectionReusableView *contentView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kProfileHeaderReuseIdentifier forIndexPath:indexPath];
		if (contentView.subviews.count == 0) {
			[contentView addSubview:_profileHeaderView];
		}
		return contentView;
	} else {
		NSLog(@"It's maybe a bug.");
		return nil;
	}
}

//点击item方法
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	ProfileCollectionViewCell *cell = (ProfileCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

	DetailViewController *vc = [[DetailViewController alloc] initWitShareItem:cell.shareItem];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)profileHeaderViewDidTouchedCover {
	if (!_playingFavorite) {
		[self playMusic:_favoriteModel.currentPlaying];
	}

	[_favoriteViewController setBackground:[UIImage getImageFromView:self.navigationController.view
															  frame:self.view.bounds]];
	[self.navigationController pushViewController:_favoriteViewController animated:YES];

}

- (void)profileHeaderViewDidTouchedPlay {
	if (!_playingFavorite) {
		[self playMusic:_favoriteModel.currentPlaying];
	} else {
		[self pauseMusic];
	}
}

- (FavoriteModel *)favoriteViewControllerModel {
	return _favoriteModel;
}

- (void)favoriteViewControllerRequestFavoriteList {
	[self requestFavoriteList];
}

- (void)favoriteViewControllerPlayMusic:(NSInteger)row {
	[self playMusic:row];
}

- (void)favoriteViewControllerPauseMusic {
	[self pauseMusic];
}

#pragma mark - Notification

- (void)notificationWebSocketDidReceiveMessage:(NSNotification *)notification {
	NSString *command = [notification userInfo][MiaAPIKey_ServerCommand];
	id ret = [notification userInfo][MiaAPIKey_Values][MiaAPIKey_Return];
	//NSLog(@"%@", command);

	if ([command isEqualToString:MiaAPICommand_Music_GetShlist]) {
		[self handleGetShareListWithRet:[ret intValue] userInfo:[notification userInfo]];
	} else if ([command isEqualToString:MiaAPICommand_User_GetStart]) {
		[self handleGetFavoriteListWitRet:[ret intValue] userInfo:[notification userInfo]];
	}
}

- (void)handleGetShareListWithRet:(int)ret userInfo:(NSDictionary *) userInfo {
	[_profileCollectionView footerEndRefreshing];

	NSArray *shareList = userInfo[@"v"][@"info"];
	if (!shareList)
		return;

	[_shareListModel addSharesWithArray:shareList];
	[_profileCollectionView reloadData];
}

- (void)handleGetFavoriteListWitRet:(int)ret userInfo:(NSDictionary *) userInfo {
	[_favoriteViewController endRequestFavoriteList:ret == 0];

	NSArray *items = userInfo[@"v"][@"data"];
	if (!items)
		return;

	[_favoriteModel addItemsWithArray:items];
	if (_favoriteViewController) {
		[_favoriteViewController.favoriteCollectionView reloadData];
	}
}

#pragma mark - audio operations

- (void)playMusic:(NSInteger)row {
	if (_favoriteModel.dataSource.count <= 0) {
		return;
	}

	_playingFavorite = YES;

	FavoriteItem *currentItem = _favoriteModel.dataSource[row];
	currentItem.isPlaying = YES;
	
	NSString *musicUrl = [[currentItem music] murl];
	NSString *musicTitle = [[currentItem music] name];
	NSString *musicArtist = [[currentItem music] singerName];

	if (!musicUrl || !musicTitle || !musicArtist) {
		NSLog(@"Music is nil, stop play it.");
		return;
	}

	[[MusicPlayerMgr standard] playWithUrl:musicUrl andTitle:musicTitle andArtist:musicArtist];
	[_profileHeaderView setIsPlaying:YES];
	[_favoriteViewController setIsPlaying:YES];

}

- (void)pauseMusic {
	[[MusicPlayerMgr standard] pause];
	[_profileHeaderView setIsPlaying:NO];
	[_favoriteViewController setIsPlaying:NO];
}

#pragma mark - button Actions

- (void)backButtonAction:(id)sender {
	if (_playingFavorite) {
		[[MusicPlayerMgr standard] stop];
	}

	[self.navigationController popViewControllerAnimated:YES];
}

- (void)settingButtonAction:(id)sender {
	NSLog(@"setting button clicked.");
}


@end
