//
//  GiteeResponse.m
//  IU_GiteeApiHelp
//
//  Created by zhuyuhui on 2021/10/22.
//

#import "GiteeResponse.h"

@implementation GiteeResponse
- (instancetype)initWithResponseObject:(id)responseObject
                            parseError:(NSError *)parseError
{
    self = [super init];
    if (self) {
        self.responseObject = responseObject;
        self.error = parseError;
        if (parseError) {
            self.success    = NO;
        }else{
            self.success    = YES;
        }
    }
    return self;

}

@end
