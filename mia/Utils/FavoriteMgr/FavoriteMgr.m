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

static const long kFavoriteRequestItemCountPerPage	= 100;

@interface FavoriteMgr()

@end

@implementation FavoriteMgr {
	NSMutableArray *_favoriteItems;
	NSMutableArray *_tempItems;
	BOOL			_isSyncing;
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationWebSocketDidReceiveMessage:) name:WebSocketMgrNotificationDidReceiveMessage object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebSocketMgrNotificationDidReceiveMessage object:nil];
}

- (long)favoriteCount {
	// TODO linyehui fav
	return [_favoriteItems count];
}

- (long)cachedCount {
	// TODO linyehui fav
	return 0;
}


- (void)syncFavoriteList {
	if (_isSyncing) {
		NSLog(@"favorite list is still syncing");
		return;
	}

	_isSyncing = YES;

	// TODO linyehui fav
	// 跟服务器进行同步，这里的同步需要处理：新增，删除，修改等操作
	[MiaAPIHelper getFavoriteListWithStart:[NSString stringWithFormat:@"%d", 0] item:kFavoriteRequestItemCountPerPage];
}

- (void)syncFinished {
	[self mergeItems];
	[self saveData];

	if (_customDelegate) {
		[_customDelegate favoriteMgrDidFinishSync];
	}

	_isSyncing = NO;
}

- (void)mergeItems {
	// TODO linyehui fav
	// 合并，找到新增和删除的，对文件进行操作，修改的暂定不做改动

	_favoriteItems = _tempItems;
	_tempItems = nil;
}

- (NSArray *)getFavoriteListFromIndex:(long)lastIndex {
	const static long kFavoriteListItemCountPerPage = 10;
	NSMutableArray * items = [[NSMutableArray alloc] init];
	for (long i = 0; i < kFavoriteListItemCountPerPage && (i + lastIndex) < _favoriteItems.count; i++) {
		[items addObject:_favoriteItems[i + lastIndex]];
	}

	return items;
}

#pragma mark - Notification

- (void)notificationWebSocketDidReceiveMessage:(NSNotification *)notification {
	NSString *command = [notification userInfo][MiaAPIKey_ServerCommand];
	id ret = [notification userInfo][MiaAPIKey_Values][MiaAPIKey_Return];
	//NSLog(@"%@", command);

	if ([command isEqualToString:MiaAPICommand_User_GetStart]) {
		[self handleGetFavoriteListWitRet:[ret intValue] userInfo:[notification userInfo]];
	}
}

- (void)handleGetFavoriteListWitRet:(int)ret userInfo:(NSDictionary *) userInfo {
	if (ret != 0) {
		[self syncFinished];
		return;
	}

	NSArray *items = userInfo[@"v"][@"data"];
	if (!items) {
		[self syncFinished];
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
		[MiaAPIHelper getFavoriteListWithStart:[NSString stringWithFormat:@"%ld", [_tempItems count]] item:kFavoriteRequestItemCountPerPage];
	} else {
		[self syncFinished];
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
