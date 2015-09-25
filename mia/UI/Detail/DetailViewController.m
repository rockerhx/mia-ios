//
//  DetailViewController.m
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "DetailViewController.h"
#import "MIAButton.h"
#import "MIALabel.h"
#import "MBProgressHUD.h"
#import "MBProgressHUDHelp.h"
#import "UIScrollView+MIARefresh.h"
#import "UIImageView+WebCache.h"
#import "UIImage+Extrude.h"
#import "CommentCollectionViewCell.h"
#import "DetailHeaderView.h"
#import "MiaAPIHelper.h"
#import "WebSocketMgr.h"
#import "ProfileShareModel.h"
#import "DetailViewController.h"
#import "CommentModel.h"
#import "CommentItem.h"

static NSString * const kDetailCellReuseIdentifier 		= @"DetailCellId";
static NSString * const kDetailHeaderReuseIdentifier 	= @"DetailHeaderId";
static NSString * const kDetailFooterReuseIdentifier 	= @"DetailFooterId";
static NSString * const kLatestCommentStart				= @"0";

static const CGFloat kDetailItemMarginH 		= 15;
static const CGFloat kDetailItemMarginV 		= 20;
static const CGFloat kDetailHeaderHeight 		= 350;
static const CGFloat kDetailFooterViewHeight 	= 40;
static const CGFloat kDetailItemHeight 			= 40;

@interface DetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, UITextFieldDelegate>

@end

@implementation DetailViewController {
	ShareItem *shareItem;
	CommentModel *commentModel;

	UICollectionView *mainCollectionView;
	UITextField *commentTextField;
	MIAButton *commentButton;

	DetailHeaderView *detailHeaderView;
	UIView *footerView;
	MBProgressHUD *progressHUD;
}

- (id)initWitShareItem:(ShareItem *)item {
	self = [super init];
	if (self) {
		shareItem = item;
		[self initUI];
		[self initData];
		[mainCollectionView addFooterWithTarget:self action:@selector(requestComments)];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidReceiveMessage:) name:WebSocketMgrNotificationDidReceiveMessage object:nil];

		//添加键盘监听
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}

	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidReceiveMessage object:nil];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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

- (void)viewDidAppear:(BOOL)animated;
{
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
	return NO;
}

- (void)initUI {
	static NSString *kDetailTitle = @"详情页";
	self.title = kDetailTitle;
	[self initBarButton];

	//1.初始化layout
	UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
	//设置collectionView滚动方向
	//    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
	//设置headerView的尺寸大小
	layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, kDetailHeaderHeight);
	layout.footerReferenceSize = CGSizeMake(self.view.frame.size.width, kDetailFooterViewHeight);

	//该方法也可以设置itemSize
	CGFloat itemWidth = self.view.frame.size.width - kDetailItemMarginH * 2;
	layout.itemSize = CGSizeMake(itemWidth, kDetailItemHeight);

	//2.初始化collectionView
	mainCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
	[self.view addSubview:mainCollectionView];

	mainCollectionView.backgroundColor = [UIColor whiteColor];

	//3.注册collectionViewCell
	//注意，此处的ReuseIdentifier 必须和 cellForItemAtIndexPath 方法中 一致 均为 cellId
	[mainCollectionView registerClass:[CommentCollectionViewCell class] forCellWithReuseIdentifier:kDetailCellReuseIdentifier];

	//注册headerView  此处的ReuseIdentifier 必须和 cellForItemAtIndexPath 方法中 一致  均为reusableView
	[mainCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailHeaderReuseIdentifier];
	[mainCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kDetailFooterReuseIdentifier];

	//4.设置代理
	mainCollectionView.delegate = self;
	mainCollectionView.dataSource = self;

	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidenKeyboard)];
	gesture.numberOfTapsRequired = 1;
	[mainCollectionView addGestureRecognizer:gesture];

	[self initHeaderView];
	[self initFooterView];
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

	UIImage *moreButtonImage = [UIImage imageNamed:@"more"];
	MIAButton *moreButton = [[MIAButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, moreButtonImage.size.width, moreButtonImage.size.height)
												 titleString:nil
												  titleColor:nil
														font:nil
													 logoImg:nil
											 backgroundImage:moreButtonImage];
	UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
	self.navigationItem.rightBarButtonItem = rightButton;
	[moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initHeaderView {
	detailHeaderView = [[DetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kDetailHeaderHeight)];
	detailHeaderView.shareItem = shareItem;

	//NSLog(@"initHeaderView: %f, %f, %f, %f", contentView.bounds.origin.x, contentView.bounds.origin.y, contentView.bounds.size.width, contentView.bounds.size.height);
	//[contentView addSubview:detailHeaderView];
}

- (void)initFooterView {
	footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kDetailFooterViewHeight)];
	footerView.backgroundColor = UIColorFromHex(@"d2d0d0", 1.0);

	UIView *textBGView = [[UIView alloc] initWithFrame:CGRectInset(footerView.frame, 1, 1)];
	textBGView.backgroundColor = UIColorFromHex(@"f2f2f2", 1.0);
	[footerView addSubview:textBGView];

	static const CGFloat kEditViewMarginLeft 		= 28;
	static const CGFloat kEditViewMarginRight 		= 70;
	static const CGFloat kEditViewMarginTop 		= 5;
	static const CGFloat kEditViewHeight			= 30;

	static const CGFloat kCommentButtonMarginRight 	= 15;
	static const CGFloat kCommentButtonMarginTop	= 10;
	static const CGFloat kCommentButtonWidth		= 50;
	static const CGFloat kCommentButtonHeight		= 20;

	commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(kEditViewMarginLeft,
																				   kEditViewMarginTop,
																				   footerView.bounds.size.width - kEditViewMarginLeft - kEditViewMarginRight,
																				   kEditViewHeight)];
	commentTextField.borderStyle = UITextBorderStyleNone;
	commentTextField.backgroundColor = [UIColor clearColor];
	commentTextField.textColor = UIColorFromHex(@"#a2a2a2", 1.0);
	commentTextField.placeholder = @"此刻的想法";
	[commentTextField setFont:UIFontFromSize(16)];
	commentTextField.keyboardType = UIKeyboardTypeDefault;
	commentTextField.returnKeyType = UIReturnKeySend;
	commentTextField.delegate = self;
	//commentTextField.backgroundColor = [UIColor yellowColor];
	[commentTextField setValue:UIColorFromHex(@"#949494", 1.0) forKeyPath:@"_placeholderLabel.textColor"];
	[commentTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

	[footerView addSubview:commentTextField];


	commentButton = [[MIAButton alloc] initWithFrame:CGRectMake(footerView.frame.size.width - kCommentButtonMarginRight - kCommentButtonWidth,
																		   kCommentButtonMarginTop,
																		   kCommentButtonWidth,
																		   kCommentButtonHeight)
										 titleString:@"发送"
										  titleColor:UIColorFromHex(@"#ff300f", 1.0)
												font:UIFontFromSize(15)
											 logoImg:nil
									 backgroundImage:nil];
	[commentButton addTarget:self action:@selector(commentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	[commentButton setTitleColor:UIColorFromHex(@"#a2a2a2", 1.0) forState:UIControlStateDisabled];
	[commentButton setEnabled:NO];
	//commentButton.backgroundColor = [UIColor redColor];
	[footerView addSubview:commentButton];
}

- (void)initData {
	commentModel = [[CommentModel alloc] init];
	[self requestComments];
}

- (void)requestComments {
	static const long kCommentPageItemCount	= 10;
	NSString *start = commentModel.lastCommentID;
	if (!start) {
		start = kLatestCommentStart;
	}

	[MiaAPIHelper getMusicCommentWithShareID:shareItem.sID start:start item:kCommentPageItemCount];
	//[MiaAPIHelper getMusicCommentWithShareID:@"244" start:start item:kCommentPageItemCount];
}

- (void)requestLatestComments {
	[MiaAPIHelper getMusicCommentWithShareID:shareItem.sID start:kLatestCommentStart item:1];
}

- (void)checkCommentButtonStatus {
	if ([commentTextField.text length] <= 0) {
		[commentButton setEnabled:NO];
	} else {
		[commentButton setEnabled:YES];
	}
}

- (void)showMBProgressHUD{
	if(!progressHUD){
		UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
		progressHUD = [[MBProgressHUD alloc] initWithView:window];
		[window addSubview:progressHUD];
		progressHUD.dimBackground = YES;
		progressHUD.labelText = @"正在提交评论";
		[progressHUD show:YES];
	}
}

- (void)removeMBProgressHUD:(BOOL)isSuccess removeMBProgressHUDBlock:(RemoveMBProgressHUDBlock)removeMBProgressHUDBlock{
	if(progressHUD){
		if(isSuccess){
			progressHUD.labelText = @"评论成功";
		}else{
			progressHUD.labelText = @"评论失败，请稍后再试";
		}
		progressHUD.mode = MBProgressHUDModeText;
		[progressHUD showAnimated:YES whileExecutingBlock:^{
			sleep(1);
		} completionBlock:^{
			[progressHUD removeFromSuperview];
			progressHUD = nil;
			if(removeMBProgressHUDBlock)
				removeMBProgressHUDBlock();
		}];
	}
}

#pragma mark - delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	const NSInteger kButtonIndex_Report = 0;
	if (kButtonIndex_Report == buttonIndex) {
		if (!progressHUD) {
			progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
			[self.view addSubview:progressHUD];
			progressHUD.labelText = NSLocalizedString(@"举报成功", nil);
			progressHUD.mode = MBProgressHUDModeText;
			[progressHUD showAnimated:YES whileExecutingBlock:^{
				sleep(2);
			} completionBlock:^{
				[progressHUD removeFromSuperview];
				progressHUD = nil;
			}];
		}
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == commentTextField) {
		[textField resignFirstResponder];
	}

	return true;
}

- (void) textFieldDidChange:(id) sender {
	[self checkCommentButtonStatus];
}

#pragma mark collectionView代理方法

//返回section个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

//每个section的item个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return commentModel.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	CommentCollectionViewCell *cell = (CommentCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kDetailCellReuseIdentifier
																											 forIndexPath:indexPath];
	[cell updateWithCommentItem:commentModel.dataSource[indexPath.row]];
	CommentItem *item = commentModel.dataSource[indexPath.row];
	NSLog(@"cell: %@", item.cmid);
	return cell;
}

//设置每个item的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat itemWidth = self.view.frame.size.width - kDetailItemMarginH * 2;
	return CGSizeMake(itemWidth, kDetailItemHeight);
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
	return kDetailItemMarginH;
}


//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return kDetailItemMarginV;
}


//通过设置SupplementaryViewOfKind 来设置头部或者底部的view，其中 ReuseIdentifier 的值必须和 注册是填写的一致，本例都为 “reusableView”
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if ([kind isEqual:UICollectionElementKindSectionHeader]) {
		UICollectionReusableView *contentView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailHeaderReuseIdentifier forIndexPath:indexPath];
		if (contentView.subviews.count == 0) {
			[contentView addSubview:detailHeaderView];
		}
		return contentView;
	} else if ([kind isEqual:UICollectionElementKindSectionFooter]) {
		UICollectionReusableView *contentView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kDetailFooterReuseIdentifier forIndexPath:indexPath];
		if (contentView.subviews.count == 0) {
			[contentView addSubview:footerView];
		}
		return contentView;
	} else {
		NSLog(@"It's maybe a bug.");
		return nil;
	}
}

//点击item方法
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//	ProfileCollectionViewCell *cell = (ProfileCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//
//	DetailViewController *vc = [[DetailViewController alloc] initWitShareItem:cell.shareItem];
//	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Notification

- (void)notificationWebSocketDidReceiveMessage:(NSNotification *)notification {
	NSString *command = [notification userInfo][MiaAPIKey_ServerCommand];
	id ret = [notification userInfo][MiaAPIKey_Values][MiaAPIKey_Return];
	//NSLog(@"%@", command);

	if ([command isEqualToString:MiaAPICommand_Music_GetMcomm]) {
		[self handleGetMusicCommentWitRet:[ret intValue] userInfo:[notification userInfo]];
	} else if ([command isEqualToString:MiaAPICommand_User_PostComment]) {
		[self handlePostCommentWitRet:[ret intValue] userInfo:[notification userInfo]];
	}
}

- (void)handleGetMusicCommentWitRet:(int)ret userInfo:(NSDictionary *) userInfo {
	[mainCollectionView footerEndRefreshing];

	if (0 != ret)
		return;
	NSArray *commentArray = userInfo[@"v"][@"info"];
	if (!commentArray || [commentArray count] <= 0)
		return;

	[commentModel addComments:commentArray];
	[mainCollectionView reloadData];
}

- (void)handlePostCommentWitRet:(int)ret userInfo:(NSDictionary *) userInfo {
	BOOL isSuccess = (0 == ret);

	if (isSuccess) {
		commentTextField.text = @"";
		[self requestLatestComments];
	} else {
	}

	[self removeMBProgressHUD:isSuccess removeMBProgressHUDBlock:^{
		if (isSuccess) {
		}
	}];
}

/*
 *   即将显示键盘的处理
 */
- (void)keyBoardWillShow:(NSNotification *)notification{
	NSDictionary *info = [notification userInfo];
	//获取当前显示的键盘高度
	CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey ] CGRectValue].size;
	[self moveUpViewForKeyboard:keyboardSize];
}

- (void)keyBoardWillHide:(NSNotification *)notification{
	[self resumeView];
}

#pragma mark - keyboard

- (void)moveUpViewForKeyboard:(CGSize)keyboardSize {
	NSTimeInterval animationDuration = 0.30f;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	float width = mainCollectionView.frame.size.width;
	float height = mainCollectionView.frame.size.height;

	CGRect rect = CGRectMake(0.0f, -keyboardSize.height, width,height);
	mainCollectionView.frame = rect;
	[UIView commitAnimations];
}

- (void)resumeView {
	NSTimeInterval animationDuration = 0.30f;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	float width = self.view.frame.size.width;
	float height = self.view.frame.size.height;
	CGRect rect = CGRectMake(0.0f, 0, width, height);
	mainCollectionView.frame = rect;
	[UIView commitAnimations];
}

- (void)hidenKeyboard {
	[commentTextField resignFirstResponder];
	[self checkCommentButtonStatus];
}

#pragma mark - button Actions

- (void)backButtonAction:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)moreButtonAction:(id)sender {
	UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"更多操作"
													 delegate:self
											cancelButtonTitle:@"取消"
									   destructiveButtonTitle:@"举报"
											otherButtonTitles: nil];
	[sheet showInView:self.view];
}

- (void)commentButtonAction:(id)sender {
	NSLog(@"comment button clicked.");
	[self showMBProgressHUD];
	[MiaAPIHelper postCommentWithShareID:shareItem.sID comment:commentTextField.text];

}

@end
