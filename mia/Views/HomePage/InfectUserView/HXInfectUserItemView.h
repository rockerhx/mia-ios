//
//  HXInfectUserItemView.h
//  mia
//
//  Created by miaios on 15/10/20.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HXInfectUserItemView : UIView

@property (weak, nonatomic) IBOutlet        UIImageView *header;
@property (weak, nonatomic) IBOutlet             UIView *whiteBorder;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerWidthContraint;

@property (nonatomic, strong) NSURL *url;

+ (instancetype)instance;

- (void)reduce;
- (void)displayWithURL:(NSURL *)url;
- (void)displayWithImageName:(NSString *)imageName;

@end