//
//  GiteeFileUtil.h
//  GiteeFileUtil
//
//  Created by zhuyuhui on 2021/10/22.
//
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "GiteeResponse.h"
// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define GiteeNetLog(s, ... ) NSLog( @"[%@ in line %d] ===============>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define GiteeNetLog(s, ... )
#endif

/// 上传或者下载的进度, Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
typedef void(^GiteeHttpProgress)(NSProgress *progress);
/// 请求成功或失败回调
typedef void(^GiteeCompletionHandler)(GiteeResponse *response);

typedef NSURL*(^GiteeDownloadDestination)(NSURL *targetPath, NSURLResponse *response);

typedef void(^GiteeDownloadCompletionHandler)(NSURLResponse *response, NSURL *filePath, NSError *error);


@interface GiteeFileUtil : NSObject
+ (instancetype)sharedInstance;
//https://gitee.com/api/v5/repos/tuay-orn/amen-data-mock/contents/json%2Fjd_addAddressPage.json
- (void)fetchGiteeReposFileWithUrl:(NSString *)url
                 completionHandler:(GiteeCompletionHandler)completionHandler;


#pragma mark - tool
+ (NSString *)base64Encode:(NSString *)data;
+ (NSString *)base64Dencode:(NSString *)data;
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

@end

