//
//  GiteeFileUtil.m
//  GiteeFileUtil
//
//  Created by zhuyuhui on 2021/10/22.
//

#import "GiteeFileUtil.h"

@interface GiteeFileUtil()
/// sessionManager
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableArray *allSessionTask;
@end

@implementation GiteeFileUtil
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static GiteeFileUtil *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

#pragma mark - network
- (void)fetchGiteeReposFileWithUrl:(NSString *)url completionHandler:(GiteeCompletionHandler)completionHandler {
    [self GET:url header:nil params:nil uploadProgressBlock:nil downloadProgressBlock:nil completionHandler:^(GiteeResponse *response) {
        if (completionHandler) {
            completionHandler(response);
        }
    }];
}

#pragma mark - tool
+ (NSString *)base64Encode:(NSString *)data{
    if (!data) {
        return nil;
    }
    NSData *sData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSData *base64Data = [sData base64EncodedDataWithOptions:0];
    NSString *baseString = [[NSString alloc]initWithData:base64Data encoding:NSUTF8StringEncoding];
    return baseString;
}
 
+ (NSString *)base64Dencode:(NSString *)data{
    if (!data) {
        return nil;
    }
    NSData *sData = [[NSData alloc]initWithBase64EncodedString:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *dataString = [[NSString alloc]initWithData:sData encoding:NSUTF8StringEncoding];
    return dataString;
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;

    }
    return dic;
}

#pragma mark - base dataTask
- (NSURLSessionDataTask *)GET:(NSString *)urlPath
               header:(NSDictionary *)header
               params:(NSDictionary *)params
    uploadProgressBlock:(GiteeHttpProgress)uploadProgressBlock
    downloadProgressBlock:(GiteeHttpProgress)downloadProgressBlock
    completionHandler:(GiteeCompletionHandler)completionHandler
{
    NSMutableDictionary *finalParams = [NSMutableDictionary dictionary];
    [finalParams addEntriesFromDictionary:params];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:urlPath parameters:params error:nil];
    request.timeoutInterval = 30;
    [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        [request setValue:value forHTTPHeaderField:key];
    }];

    __block NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        [[self allSessionTask] removeObject:task];

        if (error) {
            NSError *parseError = [self _errorFromRequestWithTask:task httpResponse:(NSHTTPURLResponse *)response responseObject:responseObject error:error];
            [self HTTPRequestLog:task body:params error:parseError];
            /// 解析参数
            GiteeResponse *ojbkResponse = [[GiteeResponse alloc] initWithResponseObject:responseObject parseError:parseError];
            if (completionHandler) {
                completionHandler(ojbkResponse);
            }
        } else {
            [self HTTPRequestLog:task body:params error:nil];
            /// 解析参数
            GiteeResponse *ojbkResponse = [[GiteeResponse alloc] initWithResponseObject:responseObject parseError:nil];
            if (completionHandler) {
                completionHandler(ojbkResponse);
            }
        }
    }];
    
    // 添加sessionTask到数组
    task ? [[self allSessionTask] addObject:task] : nil ;
    [task resume];
    return task;
}

//下载
- (NSURLSessionDownloadTask *)downloadTaskithUrlPath:(NSString *)urlPath
          header:(NSDictionary *)header
          params:(NSDictionary *)params
        progress:(GiteeHttpProgress)downloadProgressBlock
     destination:(GiteeDownloadDestination)destination
completionHandler:(GiteeDownloadCompletionHandler)completionHandler
{
    
    NSMutableDictionary *finalParams = [NSMutableDictionary dictionary];
    [finalParams addEntriesFromDictionary:params];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:urlPath parameters:params error:nil];
    request.timeoutInterval = 30;
    [header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        [request setValue:value forHTTPHeaderField:key];
    }];

    __block NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (downloadProgressBlock) {
            downloadProgressBlock(downloadProgress);
        }
        GiteeNetLog(@"totalUnitCount:%lld  completedUnitCount: %lld",downloadProgress.totalUnitCount,downloadProgress.completedUnitCount);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        if (destination) {
            return destination(targetPath,response);
        }
        
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allSessionTask] removeObject:task];

        if (completionHandler) {
            completionHandler(response,filePath,error);
        }
        GiteeNetLog(@"File downloaded to: %@", filePath);
    }];
    // 添加sessionTask到数组
    task ? [[self allSessionTask] addObject:task] : nil ;
    [task resume];
    return task;

}

#pragma mark - Error Handling
/// 请求错误解析
- (NSError *)_errorFromRequestWithTask:(NSURLSessionTask *)task httpResponse:(NSHTTPURLResponse *)httpResponse responseObject:(NSDictionary *)responseObject error:(NSError *)error {
    NSInteger HTTPCode = httpResponse.statusCode;
    NSString *errorDesc = @"服务器出错了，请稍后重试~";
    /// 其实这里需要处理后台数据错误，一般包在 responseObject
    /// HttpCode错误码解析 https://www.guhei.net/post/jb1153
    /// 1xx : 请求消息 [100  102]
    /// 2xx : 请求成功 [200  206]
    /// 3xx : 请求重定向[300  307]
    /// 4xx : 请求错误  [400  417] 、[422 426] 、449、451
    /// 5xx 、600: 服务器错误 [500 510] 、600
    NSInteger httpFirstCode = HTTPCode/100;
    if (httpFirstCode > 0) {
        if (httpFirstCode == 4) {
            /// 请求出错了，请稍后重试
            if (HTTPCode == 408) {
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = @"请求超时，请稍后再试(408)~";
#else
                errorDesc = @"请求超时，请稍后再试~";
#endif
            }else{
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = [NSString stringWithFormat:@"请求出错了，请稍后重试(%zd)~",HTTPCode];
#else
                errorDesc = @"请求出错了，请稍后重试~";
#endif
            }
        } else if (httpFirstCode == 5 || httpFirstCode == 6){
            /// 服务器出错了，请稍后重试
#if defined(DEBUG)||defined(_DEBUG)
            errorDesc = [NSString stringWithFormat:@"服务器出错了，请稍后重试(%zd)~",HTTPCode];
#else
            errorDesc = @"服务器出错了，请稍后重试~";
#endif
            
        } else if (!self.sessionManager.reachabilityManager.isReachable){
            /// 网络不给力，请检查网络
            errorDesc = @"网络开小差了，请稍后重试~";
        }
    } else {
        if (!self.sessionManager.reachabilityManager.isReachable){
            /// 网络不给力，请检查网络
            errorDesc = @"网络开小差了，请稍后重试~";
        }
    }
    
    /// 从error中解析
    if ([error.domain isEqual:NSURLErrorDomain]) {
#if defined(DEBUG)||defined(_DEBUG)
        errorDesc = [NSString stringWithFormat:@"请求出错了，请稍后重试(%zd)~",error.code];
#else
        errorDesc = @"请求出错了，请稍后重试~";
#endif
        switch (error.code) {
            case NSURLErrorSecureConnectionFailed:
            case NSURLErrorServerCertificateHasBadDate:
            case NSURLErrorServerCertificateHasUnknownRoot:
            case NSURLErrorServerCertificateUntrusted:
            case NSURLErrorServerCertificateNotYetValid:
            case NSURLErrorClientCertificateRejected:
            case NSURLErrorClientCertificateRequired:
                break;
            case NSURLErrorTimedOut:{
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = @"请求超时，请稍后再试(-1001)~";
#else
                errorDesc = @"请求超时，请稍后再试~";
#endif
                break;
            }
            case NSURLErrorNotConnectedToInternet:{
#if defined(DEBUG)||defined(_DEBUG)
                errorDesc = @"网络开小差了，请稍后重试(-1009)~";
#else
                errorDesc = @"网络开小差了，请稍后重试~";
#endif
                break;
            }
        }
    }

    NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithDictionary:error.userInfo];
    dict[NSLocalizedDescriptionKey] = errorDesc;
    return [NSError errorWithDomain:error.domain code:error.code userInfo:dict];
}

#pragma mark - 打印请求日志
- (void)HTTPRequestLog:(NSURLSessionTask *)task body:params error:(NSError *)error {
    GiteeNetLog(@">>>>>>>>>>>>>>>>>>>>>👇 REQUEST FINISH 👇>>>>>>>>>>>>>>>>>>>>>>>>>>");
    GiteeNetLog(@"Request%@=======>:%@", error?@"失败":@"成功", task.currentRequest.URL.absoluteString);
    GiteeNetLog(@"requestBody======>:%@", params);
    GiteeNetLog(@"requstHeader=====>:%@", task.currentRequest.allHTTPHeaderFields);
    GiteeNetLog(@"response=========>:%@", task.response);
    GiteeNetLog(@"error============>:%@", error);
    GiteeNetLog(@"<<<<<<<<<<<<<<<<<<<<<👆 REQUEST FINISH 👆<<<<<<<<<<<<<<<<<<<<<<<<<<");
}

#pragma mark - 懒加载
- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_sessionManager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _sessionManager.requestSerializer.timeoutInterval = 30.0f;//默认是60秒的超时时间
        [_sessionManager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        [_sessionManager.requestSerializer setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }
    
    return _sessionManager;
}

- (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}


@end
