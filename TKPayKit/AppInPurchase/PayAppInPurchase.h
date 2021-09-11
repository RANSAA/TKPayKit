//
//  PayAppInPurchase.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import <Foundation/Foundation.h>
#import "PayBaseMacro.h"


/**
 Receipt Validation Programming Guide:   https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/validating_receipts_with_the_app_store#//apple_ref/doc/uid/TP40010573-CH104-SW1
 verifyReceipt: https://developer.apple.com/documentation/appstorereceipts/verifyreceipt
 requestBody:   https://developer.apple.com/documentation/appstorereceipts/requestbody
 responseBody:  https://developer.apple.com/documentation/appstorereceipts/responsebody
 expiration_intent: https://developer.apple.com/documentation/appstorereceipts/expiration_intent
 
 */

NS_ASSUME_NONNULL_BEGIN

@interface PayAppInPurchase : NSObject

#pragma mark 内购环境配置
/**
 验证类型：0：在该工具中自动验证支付凭证   1：使用自己的服务器验证支付凭证
 警告：不建议直接在App内部调用App Store服务器verifyReceipt这样做不安全。
 */
@property(class, nonatomic, assign) NSInteger verifyType;
@property(class, nonatomic, strong, nonnull) NSString *userID; //标记不同用户


#pragma mark 支付成功之后验证凭证所需
//为了在验证**自动续期订阅**时提高您的 App 与 Apple 服务器交易的安全性，您可以在收据中包含一个 32 位随机生成的字母数字字符串，作为共享密钥。
@property(class, nonatomic, strong, nullable) NSString *password;//共享密码，
//将此值设置为true以使响应仅包含任何订阅的最新续订交易。此字段仅用于包含自动续订订阅的应用收据。
@property(class, nonatomic, assign) BOOL excludeOldTransactions;





/** 注册Store */
+ (void)registerApp;

+ (void)payPequestProducts:(NSArray<NSString *> *)products quantity:(NSUInteger)quantity completion:(void(^)(BOOL success, NSString* msg))completion
;

@end

NS_ASSUME_NONNULL_END
