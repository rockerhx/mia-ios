//
//  FavoriteMgr.m
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//
//

#import "FavoriteMgr.h"
#import "WebSocketMgr.h"
#import "MiaAPIHelper.h"
#import "FavoriteItem.h"
#import "PathHelper.h"
#import "UserSession.h"
#import "AFNetworking.h"
#import "AFNHttpClient.h"
#import "NSString+IsNull.h"

static const long kFavoriteRequestItemCountPerPage	= 100;

@interface FavoriteMgr()

@end

@implementation FavoriteMgr {
	NSMutableArray 				*_favoriteItems;
	NSMutableArray 				*_tempItems;
	BOOL						_isSyncing;

	NSURLSessionDownloadTask 	*_downloadTask;
	long						_currentDownloadIndex;
}

/**
 *  使用单例初始化
 *
 */
+(id)standard{
    static FavoriteMgr *aMgr = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        aMgr = [[self alloc] init];
    });
    return aMgr;
}

- (id)init {
	self = [super init];
	if (self) {
		[self loadData];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReachabilityStatusChange:) name:NetworkNotificationReachabilityStatusChange object:nil];
	}
	return self;
}

- (void)dealloc {
	if (_downloadTask) {
		[_downloadTask cancel];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NetworkNotificationReachabilityStatusChange object:nil];
}

- (long)favoriteCount {
	return [_favoriteItems count];
}

- (long)cachedCount {
	long count = 0;
	for (FavoriteItem *item in _favoriteItems) {
		if (item.isCached) {
			count++;
		}
	}
	return count;
}


- (void)syncFavoriteList {
	if (_isSyncing) {
		NSLog(@"favorite list is still syncing");
		return;
	}

	_isSyncing = YES;
	[MiaAPIHelper getFavoriteListWithStart:[NSString stringWithFormat:@"%d", 0]
									  item:kFavoriteRequestItemCountPerPage
							 completeBlock:^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
								 [self handleGetFavoriteListWitRet:success userInfo:userInfo];
							 } timeoutBlock:^(MiaRequestItem *requestItem) {
								 NSLog(@"GetFavoriteList timeout");
								 [self syncFinished:NO];
							 }];
}

- (NSArray *)getFavoriteListFromIndex:(long)lastIndex {
	const static long kFavoriteListItemCountPerPage = 10;
	NSMutableArray * items = [[NSMutableArray alloc] init];
	for (long i = 0; i < kFavoriteListItemCountPerPage && (i + lastIndex) < _favoriteItems.count; i++) {
		[items addObject:_favoriteItems[i + lastIndex]];
	}

	return items;
}

- (void)removeSelectedItems {
	NSEnumerator *enumerator = [_favoriteItems reverseObjectEnumerator];
	for (FavoriteItem *item in enumerator) {
		if (item.isSelected) {

			// 如果删除的是当前正在下载的任务
			if (_downloadTask
				&& [[[[_downloadTask originalRequest] URL] absoluteString] isEqualToString:item.music.murl]) {
				[_downloadTask cancel];
			}

			[self deleteCacheFileWithUrl:item.music.murl];
			[_favoriteItems removeObject:item];
		}
	}
	
	[self saveData];
}

#pragma mark - private method

- (void)syncFinished:(BOOL)isSuccess {
	if (isSuccess) {
		// 服务器获取成功才需要合并到本地
		if ([self mergeItems]) {
			[self saveData];
		}
	}

	if (_customDelegate) {
		[_customDelegate favoriteMgrDidFinishSync];
	}

	_isSyncing = NO;

	if (isSuccess && 0 == _currentDownloadIndex) {
		[self downloadFavorite];
	} else {
		NSLog(@"download task did not started: %d", isSuccess);
	}
}

- (BOOL)isItemInArray:(FavoriteItem *)item array:(NSArray *)array {
	for (FavoriteItem *it in array) {
		if ([[item fID] isEqualToString:[it fID]]) {
			return YES;
		}
	}

	return NO;
}

- (BOOL)mergeItems {
	BOOL hasDataChanged = NO;

	// 寻找删除的元素
	NSEnumerator *enumerator = [_favoriteItems reverseObjectEnumerator];
	for (FavoriteItem *item in enumerator) {
		if (![self isItemInArray:item array:_tempItems]) {
			[self deleteCacheFileWithUrl:item.music.murl];
			item.isCached = NO;
			[_favoriteItems removeObject:item];
			hasDataChanged = YES;
		}
	}

	for (FavoriteItem *newItem in _tempItems) {
		if (![self isItemInArray:newItem array:_favoriteItems]) {
			// TODO linyehui fav
			// 插入时的排序
			[_favoriteItems addObject:newItem];
			hasDataChanged = YES;
		}
	}

	_tempItems = nil;
	return hasDataChanged;
}

- (void)deleteCacheFileWithUrl:(NSString *)url {
	NSString *filename = [PathHelper genMusicFilenameWithUrl:url];
	NSError *error;
	[[NSFileManager defaultManager] removeItemAtPath:filename error:&error];
}

- (void)downloadFavorite {
	// 多线程下载收藏的歌曲
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
		FavoriteItem *item = [self getNextDownloadItem];
		if (!item
			|| [NSString isNull:item.music.murl]
			|| ![[WebSocketMgr standard] isWifiNetwork]) {
			// 断网后也会从0重新开始查找需要下载的歌曲
			_currentDownloadIndex = 0;
			[self saveData];

			dispatch_sync(dispatch_get_main_queue(), ^{
				if (_customDelegate) {
					[_customDelegate favoriteMgrDidFinishDownload];
				}
			});

			return;
		}

		_downloadTask = [AFNHttpClient downloadWithURL:item.music.murl
											  savePath:[PathHelper genMusicFilenameWithUrl:item.music.murl]
										 completeBlock:
						 ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
							 if (nil == error) {
								 [_favoriteItems[_currentDownloadIndex] setIsCached:YES];
							 } else {
								 if (filePath) {
									 NSError *fileError;
									 [[NSFileManager defaultManager] removeItemAtPath:[filePath absoluteString] error:&fileError];
								 }
							 }

							 _downloadTask = nil;
							 _currentDownloadIndex++;
							 [self downloadFavorite];
						 }];
	});
}

- (FavoriteItem *)getNextDownloadItem {
	FavoriteItem *item = nil;
	for (; _currentDownloadIndex < _favoriteItems.count; _currentDownloadIndex++) {
		item = _favoriteItems[_currentDownloadIndex];
		if (![self isItemCached:item]) {
			return item;
		}
	}

	return nil;
}

- (BOOL)isItemCached:(FavoriteItem *)item {
	if (nil == item) {
		return NO;
	}
	if (!item.isCached) {
		return NO;
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath:[PathHelper genMusicFilenameWithUrl:item.music.murl]]) {
		item.isCached = NO;
		return NO;
	}

	item.isCached = YES;
	return YES;
}

#pragma mark - Notification

- (void)notificationReachabilityStatusChange:(NSNotification *)notification {
	id status = [notification userInfo][NetworkNotificationKey_Status];
	if ([status intValue] != AFNetworkReachabilityStatusReachableViaWiFi) {
		if (_downloadTask) {
			NSLog(@"cancel current download");
			[_downloadTask cancel];
		}
	}
}

- (void)handleGetFavoriteListWitRet:(BOOL)success userInfo:(NSDictionary *) userInfo {
	if (!success) {
		[self syncFinished:NO];
		return;
	}

	NSArray *items = userInfo[@"v"][@"data"];
	if (!items) {
		[self syncFinished:NO];
		return;
	}

	if (nil == _tempItems) {
		_tempItems = [[NSMutableArray alloc] init];
	}
	
	for(id item in items){
		FavoriteItem *favoriteItem = [[FavoriteItem alloc] initWithDictionary:item];
		[_tempItems addObject:favoriteItem];
	}

	if ([items count] == kFavoriteRequestItemCountPerPage) {
		[MiaAPIHelper getFavoriteListWithStart:[NSString stringWithFormat:@"%lu", (unsigned long)[_tempItems count]]
										  item:kFavoriteRequestItemCountPerPage
								 completeBlock:^(MiaRequestItem *requestItem, BOOL success, NSDictionary *userInfo) {
									 [self handleGetFavoriteListWitRet:success userInfo:userInfo];
								 } timeoutBlock:^(MiaRequestItem *requestItem) {
									 NSLog(@"GetFavoriteList timeout");
								 }];
	} else {
		[self syncFinished:YES];
	}
}

- (void)loadData {
	_favoriteItems = [NSKeyedUnarchiver unarchiveObjectWithFile:[PathHelper favoriteArchivePathWithUID:[[UserSession standard] uid]]];
	if (!_favoriteItems) {
		_favoriteItems = [[NSMutableArray alloc] init];
	}
}

- (BOOL)saveData {
	NSString *fileName = [PathHelper favoriteArchivePathWithUID:[[UserSession standard] uid]];
	if (![NSKeyedArchiver archiveRootObject:_favoriteItems toFile:fileName]) {
		NSLog(@"archive share list failed.");
		if ([[NSFileManager defaultManager] removeItemAtPath:fileName error:nil]) {
			NSLog(@"delete share list archive file.");
		}
		return NO;
	}

	return YES;
}

//将对象编码(即:序列化)
- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_favoriteItems forKey:@"favoriteItems"];
}

//将对象解码(反序列化)
-(id) initWithCoder:(NSCoder *)aDecoder {
	if (self=[super init]) {
		_favoriteItems = [aDecoder decodeObjectForKey:@"favoriteItems"];
	}

	return (self);
	
}

@end