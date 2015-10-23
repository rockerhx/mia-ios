//
//  HXHomePageViewController.h
//  mia
//
//  Created by miaios on 15/10/9.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXWaveView;
@class HXBubbleView;
@class HXInfectUserView;
@class HXRadioViewController;

@interface HXHomePageViewController : UIViewController

@property (weak, nonatomic) IBOutlet          UILabel *songNameLabel;
@property (weak, nonatomic) IBOutlet          UILabel *songerNameLabel;
@property (weak, nonatomic) IBOutlet         UIButton *profileButton;
@property (weak, nonatomic) IBOutlet         UIButton *shareButton;
@property (weak, nonatomic) IBOutlet       HXWaveView *waveView;
@property (weak, nonatomic) IBOutlet     HXBubbleView *bubbleView;
@property (weak, nonatomic) IBOutlet      UIImageView *fishView;
@property (weak, nonatomic) IBOutlet HXInfectUserView *infectUserView;
@property (weak, nonatomic) IBOutlet          UILabel *pushPromptLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waveViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waveViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fishBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerViewBottomConstraint;

@property (weak, nonatomic) IBOutlet   UIPanGestureRecognizer *panGesture;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeGesture;

@property (nonatomic, weak) HXRadioViewController *radioViewController;

- (IBAction)profileButtonPressed;
- (IBAction)shareButtonPressed;

- (IBAction)gestureEvent:(UIGestureRecognizer *)gesture;

@end
