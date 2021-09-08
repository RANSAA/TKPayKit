//
//  PayAppInPurchase.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import <Foundation/Foundation.h>
#import "PayBaseMacro.h"


NS_ASSUME_NONNULL_BEGIN

@interface PayAppInPurchase : NSObject
@property(class, nonatomic, assign) NSInteger verifyType; //验证类型 0：直接用过Apple服务器验证（default）  1：使用自己的服务器验证
@property(class, nonatomic, strong, nonnull) NSString *userID; //标记不同用户

/** 注册Store */
+ (void)registerApp;

+ (void)payPequestProducts:(NSArray<NSString *> *)products quantity:(NSUInteger)quantity completion:(void(^)(BOOL success, NSString* msg))completion
;

@end

NS_ASSUME_NONNULL_END
