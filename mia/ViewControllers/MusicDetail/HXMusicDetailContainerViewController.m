//
//  HXMusicDetailContainerViewController.m
//  mia
//
//  Created by miaios on 15/10/26.
//  Copyright © 2015年 Mia Music. All rights reserved.
//

#import "HXMusicDetailContainerViewController.h"
#import "HXMusicDetailCoverCell.h"
#import "HXMusicDetailSongCell.h"
#import "HXMusicDetailShareCell.h"
#import "HXMusicDetailPromptCell.h"
#import "HXMusicDetailNoCommentCell.h"
#import "HXMusicDetailCommentCell.h"
#import "ShareItem.h"
#import "MiaAPIHelper.h"
#import "HXAlertBanner.h"
#import "HXInfectListView.h"
#import "InfectItem.h"
#import "LocationMgr.h"
#import "MBProgressHUDHelp.h"
#import "HXTextView.h"
#import "FavoriteMgr.h"
#import "NSString+IsNull.h"
#import "HXProfileViewController.h"
#import "WebSocketMgr.h"
#import "MusicMgr.h"
#import "HXUserSession.h"

@interface HXMusicDetailContainerViewController () <HXMusicDetailCoverCellDelegate, HXMusicDetailShareCellDelegate, HXMusicDetailPromptCellDelegate, HXMusicDetailCommentCellDelegate>
@end

@implementation HXMusicDetailContainerViewController

#pragma mark - View Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadConfigure];
    [self viewConfigure];
}

#pragma mark - Config Methods
- (void)loadConfigure {
    ;
}

- (void)viewConfigure {
    self.tableView.scrollsToTop = YES;
}

#pragma mark - Public Methods
- (void)reload {
    [self.tableView reloadData];
}

#pragma mark - Private Methods
- (void)tableView:(UITableView *)tableView scrollTableToBottom:(BOOL)animated {
    NSInteger section = [tableView numberOfSections];
    if (section < 1) return;
    NSInteger row = [tableView numberOfRowsInSection:(section - 1)];
    if (row < 1) return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(row - 1) inSection:(section - 1)];
    
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

#pragma mark - Table View Data Source Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _viewModel.rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    HXMusicDetailRow rowType = [_viewModel.rowTypes[indexPath.row] integerValue];
    switch (rowType) {
        case HXMusicDetailRowCover: {
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMusicDetailCoverCell class]) forIndexPath:indexPath];
            break;
        }
        case HXMusicDetailRowSong: {
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMusicDetailSongCell class]) forIndexPath:indexPath];
            break;
        }
        case HXMusicDetailRowShare: {
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMusicDetailShareCell class]) forIndexPath:indexPath];
            break;
        }
        case HXMusicDetailRowPrompt: {
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMusicDetailPromptCell class]) forIndexPath:indexPath];
            break;
        }
        case HXMusicDetailRowNoComment: {
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMusicDetailNoCommentCell class]) forIndexPath:indexPath];
            break;
        }
        case HXMusicDetailRowComment: {
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXMusicDetailCommentCell class]) forIndexPath:indexPath];
            break;
        }
    }
    return cell;
}

#pragma mark - Table View Delegate Methods
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    HXMusicDetailRow rowType = [_viewModel.rowTypes[indexPath.row] integerValue];
    switch (rowType) {
        case HXMusicDetailRowCover: {
            [(HXMusicDetailCoverCell *)cell displayWithViewModel:_viewModel];
            break;
        }
        case HXMusicDetailRowSong: {
            [(HXMusicDetailSongCell *)cell displayWithPlayItem:_viewModel.playItem];
            break;
        }
        case HXMusicDetailRowShare: {
            [(HXMusicDetailShareCell *)cell displayWithShareItem:_viewModel.playItem];
            break;
        }
        case HXMusicDetailRowPrompt: {
            [(HXMusicDetailPromptCell *)cell displayWithViewModel:_viewModel];
            break;
        }
        case HXMusicDetailRowNoComment: {
            break;
        }
        case HXMusicDetailRowComment: {
            [(HXMusicDetailCommentCell *)cell displayWithComment:_viewModel.comments[indexPath.row - _viewModel.regularRow]];
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.0f;
    if (_viewModel) {
        HXMusicDetailRow rowType = [_viewModel.rowTypes[indexPath.row] integerValue];
        switch (rowType) {
            case HXMusicDetailRowCover: {
                height = _viewModel.coverCellHeight;
                break;
            }
            case HXMusicDetailRowSong: {
                height = [tableView fd_heightForCellWithIdentifier:NSStringFromClass([HXMusicDetailSongCell class]) cacheByIndexPath:indexPath configuration:
                 ^(HXMusicDetailSongCell *cell) {
                     [cell displayWithPlayItem:_viewModel.playItem];
                }];
                break;
            }
            case HXMusicDetailRowShare: {
                height = [tableView fd_heightForCellWithIdentifier:NSStringFromClass([HXMusicDetailShareCell class]) cacheByIndexPath:indexPath configuration:
                 ^(HXMusicDetailShareCell *cell) {
                     [cell displayWithShareItem:_viewModel.playItem];
                 }];
                break;
            }
            case HXMusicDetailRowPrompt: {
                height = _viewModel.promptCellHeight;
                break;
            }
            case HXMusicDetailRowNoComment: {
                height = _viewModel.noCommentCellHeight;
                break;
            }
            case HXMusicDetailRowComment: {
                height = [tableView fd_heightForCellWithIdentifier:NSStringFromClass([HXMusicDetailCommentCell class]) cacheByIndexPath:indexPath configuration:
                 ^(HXMusicDetailCommentCell *cell) {
                     [cell displayWithComment:_viewModel.comments[indexPath.row - _viewModel.regularRow]];
                 }];
                break;
            }
        }
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ((indexPath.row >= _viewModel.regularRow) && (_viewModel.comments.count)) {
        HXComment *comment = _viewModel.comments[indexPath.row - _viewModel.regularRow];
        if (_delegate && [_delegate respondsToSelector:@selector(containerViewControllerAtComment:at:)]) {
            [_delegate containerViewControllerAtComment:self at:comment];
        }
    }
}

#pragma mark - HXMusicDetailCoverCellDelegate Methods
- (void)coverCell:(HXMusicDetailCoverCell *)cell takeAction:(HXMusicDetailCoverCellAction)action {
    switch (action) {
        case HXMusicDetailCoverCellActionPlay: {
            [[MusicMgr standard] setPlayListWithItem:_viewModel.playItem hostObject:self];
            [[MusicMgr standard] playCurrent];
            break;
        }
        case HXMusicDetailCoverCellActionPause: {
            break;
        }
    }
}

#pragma mark - HXMusicDetailSongCellDelegate Methods
- (void)cellUserWouldLikeStar:(HXMusicDetailSongCell *)cell {
    ShareItem *playItem = _viewModel.playItem;
    [MiaAPIHelper favoriteMusicWithShareID:playItem.sID
                                isFavorite:!playItem.favorite
                             completeBlock:
     ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
         if (success) {
             id act = userInfo[MiaAPIKey_Values][@"act"];
             id sID = userInfo[MiaAPIKey_Values][@"id"];
             BOOL favorite = [act intValue];
             if ([playItem.sID integerValue] == [sID intValue]) {
                 playItem.favorite = favorite;
                 //                     [cell updateStatStateWithFavorite:favorite];
             }
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
}

#pragma mark - HXMusicDetailShareCellDelegate Methods
- (void)shareCell:(HXMusicDetailShareCell *)cell takeAction:(HXMusicDetailShareCellAction)action {
    switch (action) {
        case HXMusicDetailShareCellActionShowSharer: {
            ShareItem *playItem = _viewModel.playItem;
            
            HXProfileViewController *profileViewController = [HXProfileViewController instance];
            profileViewController.uid = playItem.uID;
            [self.navigationController pushViewController:profileViewController animated:YES];
            break;
        }
    }
}

#pragma mark - HXMusicDetailPromptCellDelegate Methods
- (void)promptCell:(HXMusicDetailPromptCell *)cell takeAction:(HXMusicDetailPromptCellAction)action {
    ShareItem *item = _viewModel.playItem;
    switch (action) {
        case HXMusicDetailPromptCellActionInfect: {
            switch ([HXUserSession share].userState) {
                case HXUserStateLogout: {
                    [self shouldLogin];
                    break;
                }
                case HXUserStateLogin: {
                    // 传播出去不需要切换歌曲，需要记录下传播的状态和上报服务器
                    [MiaAPIHelper InfectMusicWithLatitude:[[LocationMgr standard] currentCoordinate].latitude
                                                longitude:[[LocationMgr standard] currentCoordinate].longitude
                                                  address:[[LocationMgr standard] currentAddress]
                                                     spID:item.spID
                                            completeBlock:
                     ^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
                         if (success) {
                             int isInfected = [userInfo[MiaAPIKey_Values][@"data"][@"isInfected"] intValue];
                             int infectTotal = [userInfo[MiaAPIKey_Values][@"data"][@"infectTotal"] intValue];
                             NSArray *infectArray = userInfo[MiaAPIKey_Values][@"data"][@"infectList"];
                             NSString *spID = [userInfo[MiaAPIKey_Values][@"data"][@"spID"] stringValue];
                             
                             if ([spID isEqualToString:_viewModel.playItem.spID]) {
                                 item.infectTotal = infectTotal;
                                 [item parseInfectUsersFromJsonArray:infectArray];
                                 item.isInfected = isInfected;
                             }
                             [HXAlertBanner showWithMessage:@"妙推成功" tap:nil];
                             [self reload];
                         } else {
                             id error = userInfo[MiaAPIKey_Values][MiaAPIKey_Error];
                             [HXAlertBanner showWithMessage:[NSString stringWithFormat:@"%@", error] tap:nil];
                         }
                     } timeoutBlock:^(MiaRequestItem *requestItem) {
                         item.isInfected = YES;
                         [HXAlertBanner showWithMessage:@"妙推失败，网络请求超时" tap:nil];
                     }];
                    break;
                }
            }
            break;
        }
        case HXMusicDetailPromptCellActionFavorite: {
            switch ([HXUserSession share].userState) {
                case HXUserStateLogout: {
                    [self shouldLogin];
                    break;
                }
                case HXUserStateLogin: {
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
                             
                             item.starCnt += (favorite ? 1 : (item.starCnt ? -1 : 0));
                             [HXAlertBanner showWithMessage:(favorite ? @"收藏成功" : @"取消收藏成功") tap:nil];
                             [cell displayWithViewModel:_viewModel];
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
            }
            break;
        }
        case HXMusicDetailPromptCellActionShowInfecter: {
            [HXInfectListView showWithSharerID:_viewModel.playItem.sID taped:^(id item, NSInteger index) {
                InfectItem *selectedItem = item;
                
                HXProfileViewController *profileViewController = [HXProfileViewController instance];
                profileViewController.uid = selectedItem.uID;
                [self.navigationController pushViewController:profileViewController animated:YES];
            }];
            break;
        }
        case HXMusicDetailPromptCellActionShowFavorite: {
            break;
        }
    }
}

#pragma mark - HXMusicDetailCommentCellDelegate Methods
- (void)commentCellAvatarTaped:(HXMusicDetailCommentCell *)cell {
    NSInteger index = [self.tableView indexPathForCell:cell].row;
    HXComment *comment = _viewModel.comments[index - _viewModel.regularRow];
    HXProfileViewController *profileViewController = [HXProfileViewController instance];
    profileViewController.uid = comment.uid;
    [self.navigationController pushViewController:profileViewController animated:YES];
}

@end
