//
//  HXMeDetailContainerViewController.m
//  mia
//
//  Created by miaios on 16/1/26.
//  Copyright © 2016年 Mia Music. All rights reserved.
//

#import "HXMeDetailContainerViewController.h"
#import "HXMeViewModel.h"
#import "HXAlertBanner.h"
#import "MiaAPIHelper.h"
#import "MusicMgr.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "MJRefresh.h"
#import "UIConstants.h"
#import "UIActionSheet+BlocksKit.h"
#import "FavoriteMgr.h"
#import "HXMusicDetailViewController.h"
#import "HXMessageCenterViewController.h"

@interface HXMeDetailContainerViewController () <
HXMeDetailHeaderDelegate,
HXMeShareCellDelegate
>
@end

@implementation HXMeDetailContainerViewController {
    HXMeViewModel *_viewModel;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MusicMgrNotificationPlayerEvent object:nil];
}

#pragma mark - View Controller Life Cycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self fetchShareItem];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadConfigure];
    [self viewConfigure];
}

+ (NSString *)segueIdentifier {
    return @"HXMeDetailContainerIdentifier";
}

#pragma mark - Configure Methods
- (void)loadConfigure {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationPlayerEvent:) name:MusicMgrNotificationPlayerEvent object:nil];
    _viewModel = [HXMeViewModel new];
}

- (void)viewConfigure {
    [self addRefreshFooter];
}

#pragma mark - Private Methods
- (void)addRefreshFooter {
    MJRefreshAutoNormalFooter *refreshFooter = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(fetchMoreShareData)];
    [refreshFooter setTitle:@"" forState:MJRefreshStateIdle];
    [refreshFooter setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    [refreshFooter setAutomaticallyHidden:YES];
    self.tableView.mj_footer = refreshFooter;
}

- (void)removeRefreshFooter {
    self.tableView.mj_footer = nil;
}

- (void)fetchShareItem {
    __weak __typeof__(self)weakSelf = self;
    [_viewModel fetchProfileListData:^(HXMeViewModel *viewModel) {
        __strong __typeof__(self)strongSelf = weakSelf;
        [strongSelf endLoad];
    } failure:^(NSString *message) {
        [HXAlertBanner showWithMessage:message tap:nil];
    }];
}

- (void)endLoad {
    [self.tableView.mj_footer endRefreshing];
    [self.tableView reloadData];
    
    BOOL hasData = _viewModel.dataSource.count;
    if (!hasData) {
        [self removeRefreshFooter];
        [self resizeFooter];
    }
    
    _promptLabel.hidden = hasData;
    _header.playView.hidden = !hasData;
}

- (void)resizeFooter {
    _footer.height = SCREEN_HEIGHT;
}

- (void)fetchMoreShareData {
    [_viewModel fetchProfileListMoreData];
}

- (void)deleteShareWithIndex:(NSInteger)index sID:(NSString *)sID {
	UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetWithTitle:nil];
    [actionSheet bk_setCancelButtonWithTitle:@"取消" handler:nil];
    [actionSheet bk_setDestructiveButtonWithTitle:@"删除" handler:^{
        [MiaAPIHelper deleteShareById:sID completeBlock:
         ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
             if (success) {
                 [HXAlertBanner showWithMessage:@"删除成功" tap:nil];
                 [_viewModel deleteShareItemWithIndex:index];
                 [self endLoad];
             } else {
                 NSString *error = userInfo[MiaAPIKey_Values][MiaAPIKey_Error];
                 [HXAlertBanner showWithMessage:error tap:nil];
             }
         } timeoutBlock:^(MiaRequestItem *requestItem) {
             [HXAlertBanner showWithMessage:@"删除失败，网络请求超时" tap:nil];
         }];
    }];
	[actionSheet showInView:self.view];
}

#pragma mark - ScrollView Delegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_delegate && [_delegate respondsToSelector:@selector(detailContainerDidScroll:scrollOffset:)]) {
        [_delegate detailContainerDidScroll:self scrollOffset:scrollView.contentOffset];
    }
}

#pragma mark - Table View Data Source Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _viewModel.rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXMeShareCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMeShareCell class]) forIndexPath:indexPath];
    return cell;
}

#pragma mark - Table View Delegate Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.0f;
	height = [tableView fd_heightForCellWithIdentifier:NSStringFromClass([HXMeShareCell class]) cacheByIndexPath:indexPath configuration:
			  ^(HXMeShareCell *cell) {
				  if (_viewModel.rows > 0) {
					  [(HXMeShareCell *)cell displayWithItem:_viewModel.dataSource[indexPath.row]];
				  }
              }];
    return height;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self resizeFooter];

	if (_viewModel.rows > 0) {
		HXMeShareCell *shareCell = (HXMeShareCell *)cell;
		[shareCell displayWithItem:_viewModel.dataSource[indexPath.row]];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HXMusicDetailViewController *detailViewController = [HXMusicDetailViewController instance];
	detailViewController.fromProfile = YES;
    detailViewController.playItem = _viewModel.dataSource[indexPath.row];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - HXMeDetailHeaderDelegate Methods
- (void)detailHeader:(HXMeDetailHeader *)header takeAction:(HXMeDetailHeaderAction)action {
    switch (action) {
        case HXMeDetailHeaderActionSetting: {
            if (_delegate && [_delegate respondsToSelector:@selector(detailContainer:takeAction:)]) {
                [_delegate detailContainer:self takeAction:HXProfileDetailContainerActionShowSetting];
            }
            break;
        }
        case HXMeDetailHeaderActionPlay: {
            [[MusicMgr standard] setPlayList:_viewModel.dataSource hostObject:self];
            [[MusicMgr standard] playCurrent];
            break;
        }
        case HXMeDetailHeaderActionShowFans: {
            if (_delegate && [_delegate respondsToSelector:@selector(detailContainer:takeAction:)]) {
                [_delegate detailContainer:self takeAction:HXProfileDetailContainerActionShowFans];
            }
            break;
        }
        case HXMeDetailHeaderActionShowFollow: {
            if (_delegate && [_delegate respondsToSelector:@selector(detailContainer:takeAction:)]) {
                [_delegate detailContainer:self takeAction:HXProfileDetailContainerActionShowFollow];
            }
            break;
        }
        case HXMeDetailHeaderActionShowMessage: {
            HXMessageCenterViewController *messageCenterViewController = [HXMessageCenterViewController instance];
            [self.navigationController pushViewController:messageCenterViewController animated:YES];
            break;
        }
    }
}

#pragma mark - HXMeShareCellDelegate Methods
- (void)shareCell:(HXMeShareCell *)cell takeAction:(HXMeShareCellAction)action {
    NSInteger index = [self.tableView indexPathForCell:cell].row;
    ShareItem *item = _viewModel.dataSource[index];
    switch (action) {
        case HXMeShareCellActionPlay: {
            NSInteger index = [self.tableView indexPathForCell:cell].row;
            [[MusicMgr standard] setPlayListWithItem:_viewModel.dataSource[index] hostObject:self];
            [[MusicMgr standard] playCurrent];
            
            [self.tableView reloadData];
            break;
        }
        case HXMeShareCellActionFavorite: {
            [MiaAPIHelper favoriteMusicWithShareID:item.sID
                                        isFavorite:!item.favorite
                                     completeBlock:
             ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
                 if (success) {
                     id act = userInfo[MiaAPIKey_Values][@"act"];
                     id sID = userInfo[MiaAPIKey_Values][@"id"];
                     BOOL favorite = [act intValue];
                     if ([item.sID integerValue] == [sID intValue]) {
                         item.favorite = favorite;
                     }
                     
                     cell.favorite = favorite;
                     [HXAlertBanner showWithMessage:(favorite ? @"收藏成功" : @"取消收藏成功") tap:nil];
                     
                     // 收藏操作成功后同步下收藏列表并检查下载
                     [[FavoriteMgr standard] syncFavoriteList];
                 } else {
                     id error = userInfo[MiaAPIKey_Values][MiaAPIKey_Error];
                     [HXAlertBanner showWithMessage:[NSString stringWithFormat:@"%@", error] tap:nil];
                 }
             } timeoutBlock:^(MiaRequestItem *requestItem) {
                 [HXAlertBanner showWithMessage:@"收藏失败，网络请求超时" tap:nil];
             }];
            break;
        }
        case HXMeShareCellActionDelete: {
			[self deleteShareWithIndex:index sID:item.sID];
            break;
        }
    }
}

#pragma mark - Notification Methods
- (void)notificationPlayerEvent:(NSNotification *)notification {
	NSString *sID = notification.userInfo[MusicMgrNotificationKey_sID];
	for (ShareItem *item in _viewModel.dataSource) {
		if ([item.sID isEqualToString:sID]) {
			[self.tableView reloadData];
		}
	}
}

@end
