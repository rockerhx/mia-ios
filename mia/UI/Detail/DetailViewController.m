//
//  DetailViewController.m
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "DetailViewController.h"
#import "MIAButton.h"
#import "MBProgressHUD.h"
#import "UIImage+Extrude.h"
#import "DetailPlayerView.h"
#import "CommentTableView.h"
#import "NSString+Emoji.h"
#import "NSString+IsNull.h"
#import "MiaAPIHelper.h"
#import "ShareItem.h"
#import "WebSocketMgr.h"

static const CGFloat kEditViewMarginLeft 		= 15;
static const CGFloat kEditViewMarginRight 		= 15;
static const CGFloat kEditViewMarginBottom 		= 15;
static const CGFloat kEditViewHeight			= 41;

static const long kCommentDefaultStart			= 0;
static const long kCommentPageItemCount			= 10;

@interface DetailViewController () <UIActionSheetDelegate>

@end

@implementation DetailViewController {
	UIScrollView *scrollView;
	DetailPlayerView *playerView;
	CommentTableView *commentTableView;
	UIView *editView;
	UITextField *commentTextField;
	MIAButton *commentButton;

	ShareItem *currentItem;

	UIView *sureOrCancleView;                               //【确定】/【取消】按钮所在视图
	CGSize keyboardSize;                                    //键盘高度
	CGFloat oldSureOrCancleViewToMove;                      //上一次的底部视图的【确定】/【取消】视图偏移高度
}

- (id)initWitShareItem:(ShareItem *)item {
	self = [super init];
	if (self) {
		currentItem = item;
		[self initUI];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidReceiveMessage:) name:WebSocketMgrNotificationDidReceiveMessage object:nil];

		[self requestCommentsFromStart:kCommentDefaultStart count:kCommentPageItemCount];
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
	//[self.view setBackgroundColor:[UIColor redColor]];
	[self initBarButton];

	scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	scrollView.delegate = self;
	scrollView.maximumZoomScale = 2.0f;
	scrollView.contentSize = self.view.bounds.size;
	scrollView.alwaysBounceHorizontal = NO;
	scrollView.alwaysBounceVertical = YES;
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	scrollView.backgroundColor = [UIColor yellowColor];
	[self.view addSubview:scrollView];

	static const CGFloat kPlayerMarginTop			= 0;
	static const CGFloat kPlayerHeight				= 320;

	playerView = [[DetailPlayerView alloc] initWithFrame:CGRectMake(0, kPlayerMarginTop, scrollView.frame.size.width, kPlayerHeight)];
	playerView.shareItem = currentItem;
	[scrollView addSubview:playerView];

	commentTableView = [[CommentTableView alloc] initWithFrame:CGRectMake(0,
																		  kPlayerMarginTop + kPlayerHeight,
																		  scrollView.frame.size.width,
																		  scrollView.frame.size.height - kPlayerHeight - kPlayerMarginTop)
														 style:UITableViewStylePlain];
	//commentTableView.backgroundColor = [UIColor redColor];
	[scrollView addSubview:commentTableView];

	[self initEditView];
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

- (void)initEditView {
	editView = [[UIView alloc] initWithFrame:CGRectMake(kEditViewMarginLeft,
															   scrollView.bounds.size.height - kEditViewMarginBottom - kEditViewHeight,
															   scrollView.bounds.size.width - kEditViewMarginLeft - kEditViewMarginRight,
																kEditViewHeight)];
	editView.backgroundColor = [UIColor redColor];
	[scrollView addSubview:editView];

	CGRect commentButtonFrame = editView.bounds;
	commentButton = [[MIAButton alloc] initWithFrame:commentButtonFrame
										 titleString:@"此刻的想法"
										  titleColor:UIColorFromHex(@"#a2a2a2", 1.0)
												font:UIFontFromSize(15)
											 logoImg:[UIImage imageExtrude:[UIImage imageNamed:@"edit_logo"]]
									 backgroundImage:[UIImage imageExtrude:[UIImage imageNamed:@"edit_bg"]]];
	[commentButton addTarget:self action:@selector(commentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	[editView addSubview:commentButton];

}

- (void)requestCommentsFromStart:(long)start count:(long)count {
	[MiaAPIHelper getMusicCommentWithShareID:[currentItem sID] start:start item:count];
}

#pragma mark - delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	const NSInteger kButtonIndex_Report = 0;
	if (kButtonIndex_Report == buttonIndex) {
		MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
		[self.view addSubview:progressHUD];
		progressHUD.labelText = NSLocalizedString(@"举报成功", nil);
		progressHUD.mode = MBProgressHUDModeText;
		[progressHUD showAnimated:YES whileExecutingBlock:^{
			sleep(2);
		} completionBlock:^{
			[progressHUD removeFromSuperview];
		}];

	}
}

#pragma mark - Notification

-(void)notificationWebSocketDidReceiveMessage:(NSNotification *)notification {
	NSString *command = [notification userInfo][MiaAPIKey_ServerCommand];
	id ret = [notification userInfo][MiaAPIKey_Values][MiaAPIKey_Return];

//	NSLog(@"command:%@, ret:%d", command, [ret intValue]);

	if ([command isEqualToString:MiaAPICommand_Music_GetMcomm]) {
		[self handleGetMusicCommentWitRet:[ret intValue] userInfo:[notification userInfo]];
	}
}

- (void)handleGetMusicCommentWitRet:(int)ret userInfo:(NSDictionary *) userInfo {
	if (0 != ret)
		return;

	NSArray *commentArray = userInfo[@"v"][@"info"];
	if (!commentArray || [commentArray count] <= 0)
		return;

	// TODO 一直没有获取到真实的评论数据，等数据有了再修改下字段
	[commentTableView addComments:commentArray];
}


#pragma mark - button Actions

- (void)backButtonAction:(id)sender {
	NSLog(@"back button clicked.");
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)moreButtonAction:(id)sender {
	NSLog(@"more button clicked.");
	UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"更多操作"
													 delegate:self
											cancelButtonTitle:@"取消"
									   destructiveButtonTitle:@"举报"
											otherButtonTitles: nil];
	[sheet showInView:self.view];
}

- (void)commentButtonAction:(id)sender {
	NSLog(@"comment button clicked.");
}

@end
