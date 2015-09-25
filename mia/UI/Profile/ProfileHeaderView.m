//
//  ProfileHeaderView.m
//  mia
//
//  Created by linyehui on 2015/09/09.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "ProfileHeaderView.h"
#import "MIALabel.h"
#import "MIAButton.h"
#import "UIImageView+WebCache.h"
#import "UIImageView+BlurredImage.h"
#import "UIImage+Extrude.h"


@implementation ProfileHeaderView {
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self){
		[self initUI];

	}

	return self;
}

- (void)initUI {
	static const CGFloat kCoverMarginTop = 44;

	CGRect coverFrame = CGRectMake(0,
								   kCoverMarginTop,
								   self.frame.size.width,
								   self.frame.size.height - kCoverMarginTop * 2);

	UIView *coverView = [[UIView alloc] initWithFrame:coverFrame];
	[self initCoverView:coverView];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(coverMaskTouchAction:)];
	[coverView addGestureRecognizer:tap];
	[self addSubview:coverView];

	[self initSubTitles];
}

- (void)initCoverView:(UIView *)coverView {
	UIImageView *coverImageView = [[UIImageView alloc] initWithFrame:coverView.bounds];
	UIImage *bannerImage = [self getBannerImageFromCover:[UIImage imageNamed:@"default_cover"] containerSize:coverView.bounds.size];
	[coverImageView setImageToBlur:bannerImage blurRadius:6.0 completionBlock:nil];
	[coverView addSubview:coverImageView];
	UIImageView *coverMaskImageView = [[UIImageView alloc] initWithFrame:coverView.bounds];
	[coverMaskImageView setImage:[UIImage imageNamed:@"profile_banner_mask"]];
	[coverView addSubview:coverMaskImageView];


	static const CGFloat kPlayButtonMarginRight = 76;
	static const CGFloat kPlayButtonMarginTop = 65;
	static const CGFloat kPlayButtonWidth = 40;

	MIAButton *playButton = [[MIAButton alloc] initWithFrame:CGRectMake(self.frame.size.width - kPlayButtonMarginRight - kPlayButtonWidth,
																		kPlayButtonMarginTop,
																		kPlayButtonWidth,
																		kPlayButtonWidth)
												 titleString:nil
												  titleColor:nil
														font:nil
													 logoImg:nil
											 backgroundImage:nil];
	[playButton setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
	[playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	[coverView addSubview:playButton];

	const static CGFloat kFavoriteCountLabelMarginRight		= 220;
	const static CGFloat kFavoriteCountLabelMarginTop		= 64;
	const static CGFloat kFavoriteCountLabelHeight			= 38;

	static const CGFloat kFavoriteMiddleLabelMarginRight 	= 120;
	static const CGFloat kFavoriteMiddleLabelMarginTop 		= 64;
	static const CGFloat kFavoriteMiddleLabelWidth 			= 100;
	static const CGFloat kFavoriteMiddleLabelHeight 		= 20;

	static const CGFloat kCachedCountLabelMarginRight 		= 120;
	static const CGFloat kCachedCountLabelMarginTop 		= 86;
	static const CGFloat kCachedCountLabelWidth 			= 100;
	static const CGFloat kCachedCountLabelHeight 			= 20;

	MIALabel *favoriteCountLabel = [[MIALabel alloc] initWithFrame:CGRectMake(0,
																			  kFavoriteCountLabelMarginTop,
																			  self.frame.size.width - kFavoriteCountLabelMarginRight,
																			  kFavoriteCountLabelHeight)
															  text:@"30"
															  font:UIFontFromSize(35.0f)
														 textColor:[UIColor whiteColor]
													 textAlignment:NSTextAlignmentRight
													   numberLines:1];
	//favoriteCountLabel.backgroundColor = [UIColor blueColor];
	[coverView addSubview:favoriteCountLabel];

	MIALabel *favoriteMiddleLabel = [[MIALabel alloc] initWithFrame:CGRectMake(self.frame.size.width - kFavoriteMiddleLabelMarginRight - kFavoriteMiddleLabelWidth,
																			   kFavoriteMiddleLabelMarginTop,
																			   kFavoriteMiddleLabelWidth,
																			   kFavoriteMiddleLabelHeight)
															   text:@"首收藏歌曲》"
															   font:UIFontFromSize(16.0f)
														  textColor:[UIColor whiteColor]
													  textAlignment:NSTextAlignmentRight
														numberLines:1];
	//favoriteMiddleLabel.backgroundColor = [UIColor greenColor];
	[coverView addSubview:favoriteMiddleLabel];

	MIALabel *cachedCountLabel = [[MIALabel alloc] initWithFrame:CGRectMake(self.frame.size.width - kCachedCountLabelMarginRight - kCachedCountLabelWidth,
																			kCachedCountLabelMarginTop,
																			kCachedCountLabelWidth,
																			kCachedCountLabelHeight)
															text:@"28首已下载到本地"
															font:UIFontFromSize(12.0f)
														  textColor:[UIColor whiteColor]
													  textAlignment:NSTextAlignmentLeft
														numberLines:1];
	//cachedCountLabel.backgroundColor = [UIColor greenColor];
	[coverView addSubview:cachedCountLabel];
}

- (void)initSubTitles {

	const static CGFloat kFavoriteIconMarginLeft	= 15;
	const static CGFloat kFavoriteIconMarginTop		= 15;
	const static CGFloat kFavoriteIconMarginWidth	= 16;

	const static CGFloat kFavoriteLabelMarginLeft	= kFavoriteIconMarginLeft + kFavoriteIconMarginWidth + 8;
	const static CGFloat kFavoriteLabelMarginTop	= 13;
	const static CGFloat kFavoriteLabelWidth		= 30;
	const static CGFloat kFavoriteLabelHeight		= 20;

	const static CGFloat kShareIconMarginLeft		= 15;
	const static CGFloat kShareIconMarginBottom		= 17;
	const static CGFloat kShareIconWidth			= 16;

	const static CGFloat kShareLabelMarginLeft		= kShareIconMarginLeft + kShareIconWidth + 8;
	const static CGFloat kShareLabelMarginBottom	= 14;
	const static CGFloat kShareLabelWidth			= 30;
	const static CGFloat kShareLabelHeight			= 20;


	// 两个子标题
	UIImageView *favoriteIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kFavoriteIconMarginLeft,
																					   kFavoriteIconMarginTop,
																					   kFavoriteIconMarginWidth,
																					   kFavoriteIconMarginWidth)];
	[favoriteIconImageView setImage:[UIImage imageNamed:@"favorite_white"]];
	[self addSubview:favoriteIconImageView];
	MIALabel *favoriteLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kFavoriteLabelMarginLeft,
																		 kFavoriteLabelMarginTop,
																		 kFavoriteLabelWidth,
																		 kFavoriteLabelHeight)
														 text:@"收藏"
														 font:UIFontFromSize(12.0f)
										   textColor:UIColorFromHex(@"a2a2a2", 1.0)
									   textAlignment:NSTextAlignmentLeft
												  numberLines:1];
	[self addSubview:favoriteLabel];

	UIImageView *shareIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kShareIconMarginLeft,
																					self.frame.size.height - kShareIconMarginBottom - kShareIconWidth,
																					kShareIconWidth,
																					kShareIconWidth)];
	[shareIconImageView setImage:[UIImage imageNamed:@"share"]];
	[self addSubview:shareIconImageView];
	MIALabel *shareLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kShareLabelMarginLeft,
																	  self.frame.size.height - kShareLabelMarginBottom - kShareLabelHeight,
																		 kShareLabelWidth,
																		 kShareLabelHeight)
														 text:@"分享"
														 font:UIFontFromSize(12.0f)
										   textColor:UIColorFromHex(@"a2a2a2", 1.0)
									   textAlignment:NSTextAlignmentLeft
												  numberLines:1];
	[self addSubview:shareLabel];

	static const CGFloat kWifiTipsLabelMarginBottom = 50;
	static const CGFloat kWifiTipsLabelHeight		= 20;

	MIALabel *wifiTipsLabel = [[MIALabel alloc] initWithFrame:CGRectMake(0,
																		 self.frame.size.height - kWifiTipsLabelMarginBottom - kWifiTipsLabelHeight,
																		 self.frame.size.width,
																		 kWifiTipsLabelHeight)
														 text:@"在非WIFI网络下，播放收藏歌曲不产生任何流量"
														 font:UIFontFromSize(12.0f)
										   textColor:[UIColor whiteColor]
									   textAlignment:NSTextAlignmentCenter
												  numberLines:1];
	[self addSubview:wifiTipsLabel];
}

- (UIImage *)getBannerImageFromCover:(UIImage *)orgImage containerSize:(CGSize)containerSize {

	NSLog(@"%f, %f, scale:%f", orgImage.size.width, orgImage.size.height, orgImage.scale);
	CGFloat cutHeight = containerSize.height * orgImage.size.width / containerSize.width;
	if (cutHeight <= 0.0) {
		cutHeight = orgImage.size.height / 3;
	}

	CGFloat cutY = orgImage.size.height / 2 - cutHeight / 2;
	if (cutY <= 0.0) {
		cutY = 0.0;
	}

	return [orgImage getSubImage:CGRectMake(0.0,
											cutY,
											orgImage.size.width,
											cutHeight)];
}

#pragma mark - button Actions

- (void)playButtonAction:(id)sender {
	NSLog(@"play button clicked.");
}

- (void)coverMaskTouchAction:(id)sender {
	NSLog(@"cover Touch Action");
}

@end