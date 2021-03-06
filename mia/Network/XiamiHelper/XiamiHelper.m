//
//  XiamiHelper.m
//  mia
//
//  Created by linyehui on 2015/09/08.
//  Copyright (c) 2015年 Mia Music. All rights reserved.
//
//

#import "XiamiHelper.h"
#import "SuggestionItem.h"
#import "SearchResultItem.h"
#import "NSString+IsNull.h"
#import "AFNetworking.h"


static NSString * const kSearchSuggestionParten 	= @"www.xiami.com/song/(\\d+).*?title=\"(.*?)\".*?span>(.*?)</strong>";
static NSString * const kSearchSuggestionURLFormat 	= @"http://www.xiami.com/ajax/search-index?key=%@";

static NSString * const kSearchResultParten 		= @"<td class=\"song_name\">[\\s\\S]*?<a target=\"_blank\" href=\"http://www.xiami.com/song/(\\d+)\".*?>(.*?)</a>[\\s\\S]*?<td class=\"song_artist\"><a.*?>(.*?)</a>[\\s\\S]*?<td class=\"song_album\"><a.*?>(.*?)</a>";
static NSString * const kSearchResultURLFormat 		= @"http://www.xiami.com/search/song/page/%lu?key=%@";

static NSString * const kSearchSongInfoURLFormat 	= @"http://www.xiami.com/song/playlist/id/%@/type/0/cat/json";

const static NSTimeInterval kSearchSyncTimeout		= 10;

@interface XiamiHelper()

@end

@implementation XiamiHelper{
}

+ (void)requestSearchSuggestionWithKey:(NSString *)key successBlock:(SuccessBlock)successBlock failedBlock:(FailedBlock)failedBlock {
	NSString *encodeKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *requestUrl = [NSString stringWithFormat:kSearchSuggestionURLFormat, encodeKey];

	NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
	config.timeoutIntervalForRequest = kSearchSyncTimeout;
	AFHTTPSessionManager* manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];

	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];

	[manager GET:requestUrl
	  parameters:nil
		progress:nil success:
	 ^(NSURLSessionTask *task, id responseObject) {
			NSString* responseText = [NSString stringWithUTF8String:[responseObject bytes]];

			NSError* error = NULL;
			NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:kSearchSuggestionParten options:0 error:&error];
			NSArray* match = [reg matchesInString:responseText options:NSMatchingReportCompletion range:NSMakeRange(0, [responseText length])];

			NSMutableArray *suggestionArray = [[NSMutableArray alloc] initWithCapacity:4];
			if (match.count != 0) {
				for (NSTextCheckingResult *matchItem in match) {
					//NSRange range = [matc range];
					//NSLog(@"%@", [responseText substringWithRange:range]);
					NSString* group1 = [responseText substringWithRange:[matchItem rangeAtIndex:1]];
					NSString* group2 = [responseText substringWithRange:[matchItem rangeAtIndex:2]];
					NSString* group3 = [responseText substringWithRange:[matchItem rangeAtIndex:3]];

					SuggestionItem *item = [[SuggestionItem alloc] init];
					item.songID = [self removeBoldTag:group1];
					item.title = [self removeBoldTag:group2];
					item.artist = [self removeBoldTag:group3];
					[suggestionArray addObject:item];
				}
			}

			if(successBlock){
				successBlock(suggestionArray);
			}
		} failure:^(NSURLSessionTask *operation, NSError *error) {
			NSLog(@"Error: %@", error);
			if(failedBlock){
				failedBlock(error);
			}
	}];
}

+ (void)requestSearchResultWithKey:(NSString *)key
							  page:(NSUInteger)page
					  successBlock:(SuccessBlock)successBlock
					   failedBlock:(FailedBlock)failedBlock {

	NSString *encodeKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *requestUrl = [NSString stringWithFormat:kSearchResultURLFormat, (unsigned long)page, encodeKey];

	NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
	config.timeoutIntervalForRequest = kSearchSyncTimeout;
	AFHTTPSessionManager* manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
	
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];

	[manager GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
		dispatch_queue_t queue = dispatch_queue_create("RequestSearchResult", NULL);
		dispatch_async(queue, ^() {
			NSString* responseText = [NSString stringWithUTF8String:[responseObject bytes]];

			NSError* error = NULL;
			NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:kSearchResultParten options:0 error:&error];
			NSArray* match = [reg matchesInString:responseText options:NSMatchingReportCompletion range:NSMakeRange(0, [responseText length])];

			NSMutableArray *resultArray = [[NSMutableArray alloc] initWithCapacity:4];
			if (match.count != 0) {
				for (NSTextCheckingResult *matchItem in match) {
					//NSRange range = [matc range];
					//NSLog(@"%@", [responseText substringWithRange:range]);
					NSString* group1 = [responseText substringWithRange:[matchItem rangeAtIndex:1]];
					NSString* group2 = [responseText substringWithRange:[matchItem rangeAtIndex:2]];
					NSString* group3 = [responseText substringWithRange:[matchItem rangeAtIndex:3]];
					NSString* group4 = [responseText substringWithRange:[matchItem rangeAtIndex:4]];

					SearchResultItem *item = [[SearchResultItem alloc] init];
					item.songID = [self removeBoldTag:group1];
					item.title = [self removeBoldTag:group2];
					item.artist = [self removeBoldTag:group3];
					item.albumName = [self removeBoldTag:group4];

					NSString *requestInfoUrl = [NSString stringWithFormat:kSearchSongInfoURLFormat, item.songID];
					NSDictionary *songInfo = [self requestWaitUntilFinishedWithURL:requestInfoUrl parameters:nil];
					if (nil != songInfo) {
						NSArray *trackList = songInfo[@"data"][@"trackList"];
						if ([NSNull null] != (NSNull *)trackList && trackList.count > 0) {
							item.songUrl = [self decodeXiamiUrl:trackList[0][@"location"]];

							item.pic = songInfo[@"data"][@"trackList"][0][@"pic"];
							if ([NSString isNull:item.pic]) {
								item.pic = @"";
							}
							item.albumPic = songInfo[@"data"][@"trackList"][0][@"album_pic"];
							if ([NSString isNull:item.albumPic]) {
								item.albumPic = item.pic;
							}

							[resultArray addObject:item];
						} else {
							NSLog(@"song without trackList.");
						}
					}

				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{
				if(successBlock){
					successBlock(resultArray);
				}
			});
		});
	} failure:^(NSURLSessionTask *operation, NSError *error) {
		if(failedBlock){
			failedBlock(error);
		}
	}];

}

+ (NSString *)requestXiamiUrlBySongID:(NSString *)songID {
	NSString *songUrl = nil;
	NSString *requestInfoUrl = [NSString stringWithFormat:kSearchSongInfoURLFormat, songID];
	NSDictionary *songInfo = [self requestWaitUntilFinishedWithURL:requestInfoUrl parameters:nil];
	if (nil != songInfo) {
		NSArray *trackList = songInfo[@"data"][@"trackList"];
		if ([NSNull null] != (NSNull *)trackList && trackList.count > 0) {
			songUrl = [self decodeXiamiUrl:trackList[0][@"location"]];
		} else {
			NSLog(@"song without trackList.");
		}
	}

	return songUrl;
}

+ (NSString *)removeBoldTag:(NSString *)html {
	if (nil == html || html.length == 0) {
		return html;
	}

	NSString *parten = @"</?b.*?>";
	NSError* error = NULL;
	NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:0 error:&error];

	NSString *result = [reg stringByReplacingMatchesInString:html options:0 range:NSMakeRange(0, html.length) withTemplate:@""];
	return result;
}

+ (NSString *)decodeXiamiUrl:(NSString *)encodedUrl {
	if (nil == encodedUrl || encodedUrl.length == 0) {
		return nil;
	}

//	encodedUrl = @"8h2fmF16225%k%8bcd45EtFii33532E3e5af3f4E-t%l.22654_FyEb%e33%np2ec44568la%%a52e65u%F.o%%%4%.u355E%45El3mxm22265mtDEd9547-lA5i%FFF_Ephef88E-6%%.a21712%3_8d67a1%5";

	int sectionCount = [[encodedUrl substringToIndex:1] intValue];
	NSString *code = [encodedUrl substringFromIndex:1];
	int length = floor(code.length / sectionCount) + 1;
	int remainder = code.length % sectionCount;
	NSMutableArray *sections = [[NSMutableArray alloc] init];
	NSMutableString *url_with_escape = [[NSMutableString alloc] init];

	// split to a few sections
	for (int i = 0; i < sectionCount; i++) {
		if (i < remainder) {
			[sections addObject:[code substringWithRange:NSMakeRange(length * i, length)]];
		} else {
			[sections addObject:[code substringWithRange:NSMakeRange((length - 1) * i + remainder, length - 1)]];
		}
	}

	// rebuild url
	for (int j = 0; j < [sections[0] length]; j++) {
		for (int k = 0; k < [sections count]; k++) {
			NSString *curSession = sections[k];
			if (j < curSession.length) {
				[url_with_escape appendFormat:@"%C", [curSession characterAtIndex:j]];
			}
		}
	}

	NSString * url_without_escape = [[url_with_escape
					   stringByReplacingOccurrencesOfString:@"+" withString:@" "]
					  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSString *result_url = [url_without_escape stringByReplacingOccurrencesOfString:@"^" withString:@"0"];

	return result_url;
}

+ (NSDictionary *)requestWaitUntilFinishedWithURL:(NSString *)url
									   parameters:(id)parameters {
	__block NSDictionary* response = nil;

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
	[manager GET:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
		response = (NSDictionary *)responseObject;
		dispatch_semaphore_signal(semaphore);

	} failure:^(NSURLSessionTask *operation, NSError *error) {
		NSLog(@"Error: %@", error);
		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

	return response;
}

@end

