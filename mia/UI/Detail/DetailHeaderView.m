//
//  DetailHeaderView.m
//  mia
//
//  Created by linyehui on 2015/09/09.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//

#import "DetailHeaderView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+ColorToImage.h"
#import "MIAButton.h"
#import "MIALabel.h"
#import "MusicPlayerMgr.h"
#import "UIImageView+WebCache.h"
#import "KYCircularView.h"
#import "PXInfiniteScrollView.h"
#import "ShareItem.h"
#import "UserSession.h"
#import "MiaAPIHelper.h"

@implementation DetailHeaderView {
	UIImageView 	*_coverImageView;
	KYCircularView	*_progressView;
	MIAButton 		*_playButton;
	MIALabel 		*_musicNameLabel;
	MIALabel 		*_musicArtistLabel;
	MIALabel 		*_sharerLabel;
	UITextView 		*_noteTextView;
	MIAButton 		*_favoriteButton;
	MIALabel 		*_commentLabel;
	MIALabel 		*_viewsLabel;
	MIALabel 		*_locationLabel;
	NSTimer 		*_progressTimer;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self){
		//self.backgroundColor = [UIColor orangeColor];
		[self initUI];
	}

	return self;
}

- (void)initUI {
	static const CGFloat kCoverWidth 				= 163;
	static const CGFloat kCoverHeight 				= 163;
	static const CGFloat kCoverMarginTop 			= 35;

	static const CGFloat kPlayButtonWidth			= 35;
	static const CGFloat kPlayButtonHeight			= 35;
	static const CGFloat kPlayButtonMarginBottom	= 12;
	static const CGFloat kPlayButtonMarginRight		= 12;

	static const CGFloat kMusicNameMarginTop 		= kCoverMarginTop + kCoverHeight + 20;
	static const CGFloat kMusicNameMarginLeft 		= 20;
	static const CGFloat kMusicArtistMarginLeft 	= 10;
	static const CGFloat kMusicNameHeight 			= 20;
	static const CGFloat kMusicArtistHeight 		= 20;

	static const CGFloat kFavoriteMarginTop 		= kMusicNameMarginTop;
	static const CGFloat kFavoriteMarginRight 		= 20;
	static const CGFloat kFavoriteWidth 			= 25;
	static const CGFloat kFavoriteHeight 			= 25;

	static const CGFloat kSharerMarginLeft 			= 20;
	static const CGFloat kSharerMarginTop 			= kMusicNameMarginTop + kMusicNameHeight + 5;
	static const CGFloat kSharerHeight 				= 20;

	static const CGFloat kNoteMarginLeft 			= 5;
	static const CGFloat kNoteMarginTop 			= kSharerMarginTop - 3;
	static const CGFloat kNoteMarginRight 			= 50;
	static const CGFloat kNoteHeight 				= 40;

	static const CGFloat kBottomViewMarginTop 		= kNoteMarginTop + kNoteHeight + 5;
	static const CGFloat kBottomViewHeight 			= 35;

	CGRect coverFrame = CGRectMake((self.bounds.size.width - kCoverWidth) / 2,
											 kCoverMarginTop,
											 kCoverWidth,
											 kCoverHeight);
	[self initProgressViewWithCoverFrame:coverFrame];

	_coverImageView = [[UIImageView alloc] initWithFrame:coverFrame];
	[_coverImageView sd_setImageWithURL:nil
					  placeholderImage:[UIImage imageNamed:@"default_cover"]];
	[self addSubview:_coverImageView];

	_playButton = [[MIAButton alloc] initWithFrame:CGRectMake(coverFrame.origin.x + coverFrame.size.width - kPlayButtonMarginRight - kPlayButtonWidth,
															 coverFrame.origin.y + coverFrame.size.height - kPlayButtonMarginBottom - kPlayButtonHeight,
															 kPlayButtonWidth,
															 kPlayButtonHeight)
									  titleString:nil
									   titleColor:nil
											 font:nil
										  logoImg:nil
								  backgroundImage:nil];
	[_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
	[_playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_playButton];

	_musicNameLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kMusicNameMarginLeft,
														  kMusicNameMarginTop,
														  self.bounds.size.width / 2 - kMusicNameMarginLeft + kMusicArtistMarginLeft,
														  kMusicNameHeight)
										  text:@""
										  font:UIFontFromSize(9.0f)
									 textColor:[UIColor blackColor]
								 textAlignment:NSTextAlignmentRight
								   numberLines:1];
	[self addSubview:_musicNameLabel];

	_musicArtistLabel = [[MIALabel alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 + kMusicArtistMarginLeft,
														  kMusicNameMarginTop,
														  self.bounds.size.width / 2 - kMusicArtistMarginLeft,
														  kMusicArtistHeight)
										  text:@""
										  font:UIFontFromSize(8.0f)
										   textColor:[UIColor grayColor]
									   textAlignment:NSTextAlignmentLeft
								   numberLines:1];
	[self addSubview:_musicArtistLabel];

	_sharerLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kSharerMarginLeft,
																  kSharerMarginTop,
																  _coverImageView.frame.origin.x - kSharerMarginLeft,
																  kSharerHeight)
												  text:@""
												  font:UIFontFromSize(9.0f)
											 textColor:[UIColor blueColor]
										 textAlignment:NSTextAlignmentRight
										   numberLines:1];
	//sharerLabel.backgroundColor = [UIColor yellowColor];
	[self addSubview:_sharerLabel];

	_noteTextView = [[UITextView alloc] initWithFrame:CGRectMake(_coverImageView.frame.origin.x + kNoteMarginLeft,
															   kNoteMarginTop,
															   self.bounds.size.width - _coverImageView.frame.origin.x - kNoteMarginRight,
																kNoteHeight)];
	_noteTextView.text = @"";
	//noteTextView.backgroundColor = [UIColor redColor];
	_noteTextView.scrollEnabled = NO;
	_noteTextView.font = UIFontFromSize(9.0f);
	_noteTextView.userInteractionEnabled = NO;
	[self addSubview:_noteTextView];

	_favoriteButton = [[MIAButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - kFavoriteMarginRight - kFavoriteWidth,
																 kFavoriteMarginTop,
																 kFavoriteWidth,
																 kFavoriteHeight)
										  titleString:nil
										   titleColor:nil
												 font:nil
											  logoImg:nil
									  backgroundImage:nil];
	[_favoriteButton setImage:[UIImage imageNamed:@"favorite_normal"] forState:UIControlStateNormal];
	[_favoriteButton addTarget:self action:@selector(favoriteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_favoriteButton];

	static const CGFloat kCommentTitleHeight			= 20;
	static const CGFloat kCommentTitleWidth				= 50;
	static const CGFloat kCommentTitleMarginTop			= kBottomViewMarginTop + kBottomViewHeight + 10;
	static const CGFloat kCommentTitleMarginLeft		= 15;

	UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0,
																  kBottomViewMarginTop,
																  self.bounds.size.width,
																  kBottomViewHeight)];
	//bottomView.backgroundColor = [UIColor yellowColor];
	[self addSubview:bottomView];

	[self initBottomView:bottomView];

	
	MIALabel *commentTitleLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kCommentTitleMarginLeft,
																			 kCommentTitleMarginTop,
																			 kCommentTitleWidth,
																			 kCommentTitleHeight)
															 text:@"评论"
															 font:UIFontFromSize(12.0f)
														textColor:UIColorFromHex(@"949494", 1.0)
													textAlignment:NSTextAlignmentLeft
													  numberLines:1];
	//commentTitleLabel.backgroundColor = [UIColor redColor];
	[self addSubview:commentTitleLabel];
}

- (void)initProgressViewWithCoverFrame:(CGRect) coverFrame {
	_progressView = [[KYCircularView alloc] initWithFrame:CGRectInset(coverFrame, -4, -4)];
	_progressView.colors = @[(__bridge id)ColorHex(0x206fff).CGColor, (__bridge id)ColorHex(0x206fff).CGColor];
	_progressView.backgroundColor = UIColorFromHex(@"dfdfdf", 255.0);
	_progressView.lineWidth = 8.0;

	CGFloat pathWidth = _progressView.frame.size.width;
	CGFloat pathHeight = _progressView.frame.size.height;
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path moveToPoint:CGPointMake(pathWidth / 2, pathHeight)];
	[path addLineToPoint:CGPointMake(pathWidth, pathHeight)];
	[path addLineToPoint:CGPointMake(pathWidth, 0)];
	[path addLineToPoint:CGPointMake(0, 0)];
	[path addLineToPoint:CGPointMake(0, pathHeight)];
	[path addLineToPoint:CGPointMake(pathWidth / 2, pathHeight)];
	[path closePath];

	_progressView.path = path;

	[self addSubview:_progressView];
}

- (void)initBottomView:(UIView *)bottomView {
	static const CGFloat kBottomButtonMarginBottom		= 5;
	static const CGFloat kBottomButtonWidth				= 15;
	static const CGFloat kBottomButtonHeight			= 15;
	static const CGFloat kCommentImageMarginLeft		= 20;
	static const CGFloat kViewsImageMarginLeft			= 60;
	static const CGFloat kLocationImageMarginRight		= 1;
	static const CGFloat kLocationLabelMarginRight		= 20;
	static const CGFloat kLocationLabelWidth			= 80;

	static const CGFloat kCommentLabelMarginLeft		= 2;
	static const CGFloat kBottomLabelMarginBottom		= 5;
	static const CGFloat kBottomLabelHeight				= 15;
	static const CGFloat kCommentLabelWidth				= 20;

	static const CGFloat kViewsLabelMarginLeft			= 2;
	static const CGFloat kViewsLabelWidth				= 20;

	UIImageView *commentsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kCommentImageMarginLeft,
																				   bottomView.bounds.size.height - kBottomButtonMarginBottom - kBottomButtonHeight,
																				   kBottomButtonWidth,
																				   kBottomButtonHeight)];
	[commentsImageView setImage:[UIImage imageNamed:@"comments"]];
	[bottomView addSubview:commentsImageView];

	_commentLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kCommentImageMarginLeft + kBottomButtonWidth + kCommentLabelMarginLeft,
															  bottomView.bounds.size.height - kBottomLabelMarginBottom - kBottomLabelHeight,
															  kCommentLabelWidth,
															  kBottomLabelHeight)
											  text:@""
											  font:UIFontFromSize(8.0f)
										 textColor:[UIColor grayColor]
									 textAlignment:NSTextAlignmentLeft
									   numberLines:1];
	//commentLabel.backgroundColor = [UIColor redColor];
	[bottomView addSubview:_commentLabel];

	UIImageView *viewsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kViewsImageMarginLeft,
																				bottomView.bounds.size.height - kBottomButtonMarginBottom - kBottomButtonHeight,
																				kBottomButtonWidth,
																				kBottomButtonHeight)];
	[viewsImageView setImage:[UIImage imageNamed:@"views"]];
	[bottomView addSubview:viewsImageView];

	_viewsLabel = [[MIALabel alloc] initWithFrame:CGRectMake(kViewsImageMarginLeft + kBottomButtonWidth + kViewsLabelMarginLeft,
															bottomView.bounds.size.height - kBottomLabelMarginBottom - kBottomLabelHeight,
															kViewsLabelWidth,
															kBottomLabelHeight)
											text:@""
											font:UIFontFromSize(8.0f)
									   textColor:[UIColor grayColor]
								   textAlignment:NSTextAlignmentLeft
									 numberLines:1];
	//viewsLabel.backgroundColor = [UIColor redColor];
	[bottomView addSubview:_viewsLabel];

	UIImageView *locationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(bottomView.bounds.size.width - kLocationLabelMarginRight - kLocationLabelWidth - kLocationImageMarginRight - kBottomButtonWidth,
																				   bottomView.bounds.size.height - kBottomButtonMarginBottom - kBottomButtonHeight,
																				   kBottomButtonWidth,
																				   kBottomButtonHeight)];
	[locationImageView setImage:[UIImage imageNamed:@"location"]];
	[bottomView addSubview:locationImageView];

	_locationLabel = [[MIALabel alloc] initWithFrame:CGRectMake(bottomView.bounds.size.width - kLocationLabelMarginRight - kLocationLabelWidth,
															   bottomView.bounds.size.height - kBottomLabelMarginBottom - kBottomLabelHeight,
															   kLocationLabelWidth,
															   kBottomLabelHeight)
											   text:@""
											   font:UIFontFromSize(8.0f)
									   textColor:[UIColor grayColor]
								   textAlignment:NSTextAlignmentLeft
									 numberLines:1];
	//locationLabel.backgroundColor = [UIColor redColor];
	[bottomView addSubview:_locationLabel];
}

- (void)setShareItem:(ShareItem *)item {
	if (!item) {
		// TODO 允许为空，要看下运行是否正常
		NSLog(@"debug nil");
	}

	_shareItem = item;

	[_coverImageView sd_setImageWithURL:[NSURL URLWithString:[[item music] purl]]
					  placeholderImage:[UIImage imageNamed:@"default_cover"]];

	[_musicNameLabel setText:[[item music] name]];
	[_musicArtistLabel setText:[[NSString alloc] initWithFormat:@" - %@", [[item music] singerName]]];
	[_sharerLabel setText:[[NSString alloc] initWithFormat:@"%@ :", [item sNick]]];
	[_noteTextView setText:[item sNote]];

	[_commentLabel setText: 0 == [item cComm] ? @"" : NSStringFromInt([item cComm])];
	[_viewsLabel setText: 0 == [item cView] ? @"" : NSStringFromInt([item cView])];
	[_locationLabel setText:[item sAddress]];

	[self updateShareButtonWithIsFavorite:item.favorite];
}

- (void)updateShareButtonWithIsFavorite:(BOOL)isFavorite {
	if (isFavorite) {
		[_favoriteButton setImage:[UIImage imageNamed:@"favorite_red"] forState:UIControlStateNormal];
	} else {
		[_favoriteButton setImage:[UIImage imageNamed:@"favorite_white"] forState:UIControlStateNormal];
	}
}

#pragma mark - notification

- (void)notifyMusicPlayerMgrDidPlay {
	[_playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
	_progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
}

- (void)notifyMusicPlayerMgrDidPause {
	[_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
	[_progressTimer invalidate];
}

#pragma mark - Actions

- (void)playButtonAction:(id)sender {
	NSLog(@"playButtonAction");
	if ([[MusicPlayerMgr standard] isPlaying]) {
		[self pauseMusic];
	} else {
		[self playMusic];
	}
}

- (void)favoriteButtonAction:(id)sender {
	NSLog(@"favoriteButtonAction");
	if ([[UserSession standard] isLogined]) {
		NSLog(@"favorite to profile page.");

		[MiaAPIHelper favoriteMusicWithShareID:_shareItem.sID isFavorite:!_shareItem.favorite];
	} else {
		[_customDelegate detailHeaderViewShouldLogin];
	}
}

#pragma mark - audio operations

- (void)playMusic {
//	static NSString *defaultMusicUrl = @"http://miadata1.ufile.ucloud.cn/1b6a1eef28716432d6a0c2dd77c77a71.mp3";
//	static NSString *defaultMusicTitle = @"贝尔加湖畔";
//	static NSString *defaultMusicArtist = @"李健";

	NSString *musicUrl = [[_shareItem music] murl];
	NSString *musicTitle = [[_shareItem music] name];
	NSString *musicArtist = [[_shareItem music] singerName];

	if (!musicUrl || !musicTitle || !musicArtist) {
		NSLog(@"Music is nil, stop play it.");
		return;
	}

	[[MusicPlayerMgr standard] playWithUrl:musicUrl andTitle:musicTitle andArtist:musicArtist];
	[_playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];

}

- (void)pauseMusic {
	[[MusicPlayerMgr standard] pause];
	[_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}

- (void)stopMusic {
	[[MusicPlayerMgr standard] stop];
	[_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}

- (void)updateProgress:(NSTimer *)timer {
	float postion = [[MusicPlayerMgr standard] getPlayPosition];
	[_progressView setProgress:postion];
}

@end
