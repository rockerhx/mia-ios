//
//  HXCardDetailView.h
//  mia
//
//  Created by miaios on 15/11/18.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import "HXXibView.h"

@class HXMusicDetailViewModel;

@interface HXCardDetailView : HXXibView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak, nullable) IBOutlet UITableView *tableView;

- (void)displayWithViewModel:(nullable HXMusicDetailViewModel *)viewModel;

@end
