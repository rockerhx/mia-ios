//
//  HXDiscoveryHeader.h
//  mia
//
//  Created by miaios on 16/2/22.
//  Copyright © 2016年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HXDiscoveryHeaderAction) {
    HXDiscoveryHeaderActionProfile,
    HXDiscoveryHeaderActionShare
};

@class HXDiscoveryHeader;

@protocol HXDiscoveryHeaderDelegate <NSObject>

@required
- (void)discoveryActionHeader:(HXDiscoveryHeader *)header takeAction:(HXDiscoveryHeaderAction)action;

@end

@interface HXDiscoveryHeader : UIView

@property (nonatomic, weak) IBOutlet id <HXDiscoveryHeaderDelegate>delegate;

- (IBAction)profileButtonPressed;
- (IBAction)shareButtonPressed;

@end
