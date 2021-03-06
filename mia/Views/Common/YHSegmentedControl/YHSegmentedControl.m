//
//  YHSegmentedControl.m
//  CustomSegControlView
//
//  Created by linyehui on 2016-01-27.
//  Copyright (c) 2016年 linyehui. All rights reserved.
//

#import "YHSegmentedControl.h"

#define YHSegmentedControl_Width ([UIScreen mainScreen].bounds.size.width)
#define Min_Width_4_Button 80.0

#define Define_Tag_add 1000

#define UIColorFromRGBValue(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface YHSegmentedControl()

@property (strong, nonatomic)UIScrollView *scrollView;
@property (strong, nonatomic)NSMutableArray *array4Btn;
@property (strong, nonatomic)UIView *cursorLineView;

@end

@implementation YHSegmentedControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithHeight:(CGFloat)height titles:(NSArray *)titles delegate:(id)delegate {
    CGRect rect4View = CGRectMake(.0f, 0, YHSegmentedControl_Width, height);
    if (self = [super initWithFrame:rect4View]) {
        
        self.backgroundColor = UIColorFromRGBValue(0xffffff);
        [self setUserInteractionEnabled:YES];
        
        self.delegate = delegate;
        
        //
        //  array4btn
        //
        _array4Btn = [[NSMutableArray alloc] initWithCapacity:[titles count]];
        
        //
        //  set button
        //
        CGFloat width4btn = rect4View.size.width/[titles count];
        if (width4btn < Min_Width_4_Button) {
            width4btn = Min_Width_4_Button;
        }
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.backgroundColor = self.backgroundColor;
        _scrollView.userInteractionEnabled = YES;
        _scrollView.contentSize = CGSizeMake([titles count]*width4btn, height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        
        for (int i = 0; i < [titles count]; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(i*width4btn, .0f, width4btn, height);
            [btn setTitleColor:UIColorFromRGBValue(0x000000) forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:17];
            [btn setTitleColor:UIColorFromRGBValue(0x0CB4A3) forState:UIControlStateSelected];
            [btn setTitle:[titles objectAtIndex:i] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(segmentedControlChange:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = Define_Tag_add+i;
            [_scrollView addSubview:btn];
            [_array4Btn addObject:btn];
            
            if (i == 0) {
                btn.selected = YES;
            }
        }
        
        //
        //  lineView
        //
        CGFloat height4Line = height / 3.0f;
        CGFloat originY = (height - height4Line) / 2;
        for (int i = 1; i < [titles count]; i++) {
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(i*width4btn-1.0f, originY, 1.0f, height4Line)];
            lineView.backgroundColor = UIColorFromRGBValue(0xcacaca);
            [_scrollView addSubview:lineView];
        }
        
        //
        //  cursor lineView
        //
        _cursorLineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, height - 4, width4btn, 3.0f)];
        _cursorLineView.backgroundColor = UIColorFromRGBValue(0x16e6d0);
        [_scrollView addSubview:_cursorLineView];

		UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, height - 1, _scrollView.bounds.size.width, 1.0f)];
		bottomLineView.backgroundColor = UIColorFromRGBValue(0xd7d7d7);
		[_scrollView addSubview:bottomLineView];

        [self addSubview:_scrollView];
    }

    return self;
}

//
//  btn clicked
//
- (void)segmentedControlChange:(UIButton *)btn {
    btn.selected = YES;
    for (UIButton *subBtn in self.array4Btn) {
        if (subBtn != btn) {
            subBtn.selected = NO;
        }
    }
    
    CGRect rect4boottomLine = self.cursorLineView.frame;
    rect4boottomLine.origin.x = btn.frame.origin.x;
    
    CGPoint pt = CGPointZero;
    BOOL canScrolle = NO;
    if ((btn.tag - Define_Tag_add) >= 2 && [_array4Btn count] > 4 && [_array4Btn count] > (btn.tag - Define_Tag_add + 2)) {
        pt.x = btn.frame.origin.x - Min_Width_4_Button*1.5f;
        canScrolle = YES;
    }else if ([_array4Btn count] > 4 && (btn.tag - Define_Tag_add + 2) >= [_array4Btn count]){
        pt.x = (_array4Btn.count - 4) * Min_Width_4_Button;
        canScrolle = YES;
    }else if (_array4Btn.count > 4 && (btn.tag - Define_Tag_add) < 2){
        pt.x = 0;
        canScrolle = YES;
    }
    
    if (canScrolle) {
        [UIView animateWithDuration:0.3 animations:^{
            _scrollView.contentOffset = pt;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                self.cursorLineView.frame = rect4boottomLine;
            }];
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.cursorLineView.frame = rect4boottomLine;
        }];
    }
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(YHSegmentedControlSelected:)]) {
        [self.delegate YHSegmentedControlSelected:btn.tag - 1000];
    }
}


// index 从 0 开始
- (void)switchToIndex:(NSInteger)index {
    if (index > [_array4Btn count]-1) {
        NSLog(@"index is out of range");
        return;
    }
    
    UIButton *btn = [_array4Btn objectAtIndex:index];
    [self segmentedControlChange:btn];
}

- (void)setTitle:(NSString *)title forIndex:(NSInteger)index {
	if (index > [_array4Btn count]-1) {
		NSLog(@"index is out of range");
		return;
	}

	UIButton *btn = [_array4Btn objectAtIndex:index];
	[btn setTitle:title forState:UIControlStateNormal];
}

@end
