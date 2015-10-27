//
//  HXMusicDetailViewController.h
//  mia
//
//  Created by miaios on 15/10/26.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShareItem;

@protocol HXMusicDetailViewControllerDelegate

- (void)detailViewControllerDidDeleteShare;

@end

@interface HXMusicDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentViewBottomConstraint;
@property (weak, nonatomic) IBOutlet  UITextView *editCommentView;

@property (weak, nonatomic)          id  <HXMusicDetailViewControllerDelegate>customDelegate;

@property (nonatomic, assign)      BOOL  fromProfile;
@property (nonatomic, strong) ShareItem *playItem;

- (IBAction)backButtonPressed;
- (IBAction)moreButtonPressed;
- (IBAction)commentButtonPressed;
- (IBAction)sendButtonPressed;

@end
