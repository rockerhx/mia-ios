//
//  HXDiscoveryContainerViewController.h
//  mia
//
//  Created by miaios on 16/2/17.
//  Copyright © 2016年 Mia Music. All rights reserved.
//

#import "iCarousel.h"

@class ShareItem;
@class HXDiscoveryContainerViewController;

typedef NS_ENUM(NSUInteger, HXDiscoveryCardAction) {
    HXDiscoveryCardActionSlidePrevious,
    HXDiscoveryCardActionSlideNext,
    HXDiscoveryCardActionPlay,
    HXDiscoveryCardActionShowSharer,
    HXDiscoveryCardActionShowInfecter,
    HXDiscoveryCardActionShowCommenter,
    HXDiscoveryCardActionShowDetail,
    HXDiscoveryCardActionInfect,
    HXDiscoveryCardActionComment,
    HXDiscoveryCardActionRefresh,
};

@protocol HXDiscoveryContainerViewControllerDelegate <NSObject>

@optional
- (void)containerViewController:(HXDiscoveryContainerViewController *)container takeAction:(HXDiscoveryCardAction)action;

@end

@interface HXDiscoveryContainerViewController : UIViewController

@property (weak, nonatomic) IBOutlet iCarousel *carousel;

@property (nonatomic, weak)          id  <HXDiscoveryContainerViewControllerDelegate>delegate;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong)   NSArray *dataSoure;

@property (nonatomic, strong, readonly) ShareItem *currentItem;

@end
