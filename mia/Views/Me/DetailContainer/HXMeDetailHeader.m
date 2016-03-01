//
//  HXMeDetailHeader.m
//  mia
//
//  Created by miaios on 16/1/28.
//  Copyright © 2016年 Mia Music. All rights reserved.
//

#import "HXMeDetailHeader.h"
#import "HXXib.h"
#import "UIImageView+WebCache.h"

@implementation HXMeDetailHeader

HXXibImplementation

#pragma mark - Load Methods
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self loadConfigure];
    [self viewConfigure];
}

#pragma mark - Configure Methods
- (void)loadConfigure {
    ;
}

- (void)viewConfigure {
    _containerView.backgroundColor = [UIColor clearColor];
}


#pragma mark - Setter And Getter
- (void)setType:(HXProfileType)type {
    _type = type;
//    _followButton.hidden = type;
}

#pragma mark - Event Response
- (IBAction)actionButtonPressed {
//    if (_delegate && [_delegate respondsToSelector:@selector(detailHeader:takeAction:)]) {
//        [_delegate detailHeader:self takeAction:HXMeDetailHeaderActionTakeFollow];
//    }
}

- (IBAction)playFMTaped {
    if (_delegate && [_delegate respondsToSelector:@selector(detailHeader:takeAction:)]) {
        [_delegate detailHeader:self takeAction:HXMeDetailHeaderActionPlayFM];
    }
}

- (IBAction)fansViewTaped {
    if (_delegate && [_delegate respondsToSelector:@selector(detailHeader:takeAction:)]) {
        [_delegate detailHeader:self takeAction:HXMeDetailHeaderActionShowFans];
    }
}

- (IBAction)followViewTaped {
    if (_delegate && [_delegate respondsToSelector:@selector(detailHeader:takeAction:)]) {
        [_delegate detailHeader:self takeAction:HXMeDetailHeaderActionShowFollow];
    }
}

#pragma mark - Public Methods
- (void)displayWithHeaderModel:(HXProfileHeaderModel *)model {
    [_avatar sd_setImageWithURL:[NSURL URLWithString:model.avatar] placeholderImage:[UIImage imageNamed:@"HP-InfectUserDefaultHeader"]];
    _nickNameLabel.text = model.nickName;
    _fansCountLabel.text = model.fansCount;
    _followCountLabel.text = model.followCount;
}

@end
