//
//  GiteeResponse.h
//  IU_GiteeApiHelp
//
//  Created by zhuyuhui on 2021/10/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GiteeResponse : NSObject
/// 成功or失败
@property(nonatomic, assign) BOOL success;
@property(nullable, nonatomic, strong) NSError *error;
@property(nullable, nonatomic, strong) id responseObject;
- (instancetype)initWithResponseObject:(nullable id)responseObject
                            parseError:(nullable NSError *)parseError;

@end

NS_ASSUME_NONNULL_END
