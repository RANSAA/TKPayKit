//
//  PayAppInPurchase.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import <Foundation/Foundation.h>
#import "PayBaseMacro.h"
#import "PayAppInPurchaseRequest.h"



/**
 参考文档

 App In Purchase：
 https://blog.51cto.com/yarin/549141
 https://www.jianshu.com/p/f7bff61e0b31
 https://blog.csdn.net/u013654125/article/details/99832989
 https://blog.csdn.net/qcx321/article/details/80847051
 https://www.jianshu.com/p/de030cd6e4a3


 非消耗品的购买与恢复:
 https://blog.csdn.net/shenjie12345678/article/details/53023804


 Receipt Validation Programming Guide:   https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/validating_receipts_with_the_app_store#//apple_ref/doc/uid/TP40010573-CH104-SW1
 Choose a Validation Technique：https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/choosing_a_receipt_validation_technique#//apple_ref/doc/uid/TP40010573
 verifyReceipt: https://developer.apple.com/documentation/appstorereceipts/verifyreceipt
 requestBody:   https://developer.apple.com/documentation/appstorereceipts/requestbody
 responseBody:  https://developer.apple.com/documentation/appstorereceipts/responsebody
 expiration_intent: https://developer.apple.com/documentation/appstorereceipts/expiration_intent
 
 */

/**
 使用说明：
 1：在didFinishLaunchingWithOptions中注册
 2：注册之后执行checkRecordReceiptDataWithCompletion：方法检测是否有缓存的数据凭证，如果有可从list.dic中循环获取receiptDic数据
 3：如果有则需要验证收据凭证是否有效，验证分两种方式；
    1.直接在APP中验证，调用verifyReceiptData：completion：方法即可
    2.在自己的服务器中验证，需要将receiptData进行base64编码，发给服务器验证
 4：验证完毕之后需要删除缓存记录使用：removeRecordReceiptDataWithKey
 5：在需要支付的地方调用：payPequestProducts:req:type:completion:或者payRequestRestoresWithApplicationUsername：方法
 6：接收支付成功/失败通知
 7：处理支付成功通知，即需要验证收据凭证数据
    1.收据凭证数据来源与通知传递,直接通过notif.userinfo.kNotificationUserInfoResultData获取receiptDic数据
    2.从checkRecordReceiptDataWithCompletion:中list.dic中获取receiptDic数据
 8：重复执行3，4条进行收据数据验证操作

 PS:注意目前该工具还未经过测试，恢复购买（payRequestRestoresWithApplicationUsername：）方式可能不完全，后期可以根据实际需求优化。
 PS:支付成功/失败需要通过监听通知消息获取，通知支付成功之后还需要验证凭据。

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

/**
 * 提交App In Purchase支付请求
 * products：需要支付的商品productID列表
 * req:附加的商品信息，如商品数量. 可选
 * type：自定义的商品类型标注，会在checkRecordReceiptDataWithCompletion:中的list.dic.type中返回
 * @completion
 * success：请求是否提交成功
 * msg：消息
 */
+ (void)payPequestProducts:(NSArray<NSString *> *)products req:(nullable PayAppInPurchaseRequest *)req type:(NSInteger)type completion:(void(^)(BOOL success, NSString* msg))completion;

/**
 * 恢复购买请求提交
 * username：特定于应用程序的用户标识符。可选的。
 * @completion
 * success：请求是否提交成功
 * msg：消息
 */
+ (void)payRequestRestoresWithApplicationUsername:(nullable NSString *)username completion:(void(^)(BOOL success, NSString* msg))completion;



/**
 * 检查是否还有未验证的支付凭据,如果有需要验证收据凭证是否有效
 * completion:在该块中检查是否有还没有验证的交易凭证
 * isVerify：YES:需要验证，NO:不需要验证
 * list：未验证的交易凭证列表，验证凭据是否有效时需要循环list列表中的item,
 * itemDic结构：
 *           type：自定义支付类型type
 *           key：记录唯一标识，可用于删除验证完毕后的交易记录缓存
 *           transactionIdentifier：该条交易凭证标识id
 *           transactionDate：交易时间
 *           receiptData：交易凭证NSData数据
 * 验证方式：
 *          1.使用自己的服务其验证凭证是否有效(推荐)
 *          2.在App类向apple服务器发送验证请求(警告这样做不安全)
 * App内验证：
 *          只需要执行verifyReceiptData:completion:验证即可
 * 验证结束：
 *          需要执行removeRecordReceiptDataWithKey：移出已经验证的收据凭证缓存。
 */
+ (void)checkRecordReceiptDataWithCompletion:(void(^)(BOOL isVerify,  NSArray<NSDictionary *>* _Nullable list))completion;

/**
 * 验证支付凭证数据，直接在App中向apple服务器发送验证信息
 * receiptData：凭证数据
 * @completion：验证完毕后回调
 * status:凭证验证状态
 *        0：失败，凭证无效
 *        1：成功。凭证有效
 *        2：网络错误，需要重新验证
 */
+ (void)verifyReceiptData:(NSData *)receiptData completion:(void(^)(NSInteger status))completion;


/**
 * 移出支付凭证记录缓存
 * key:记录唯一标识，从checkRecordReceiptDataWithCompletion:回调中的list.dic.key中获取
 */
+ (NSString *)removeRecordReceiptDataWithKey:(NSString *)key;


@end

NS_ASSUME_NONNULL_END
