//
//  PayAppInPurchaseRequest.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/12.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * App In Purchase 提交时的额外参数model
 * 该Model为每个productID请求时的补充参数
 * 即与SKMutablePayment中属性有着相同功能的属性
 */


@interface PayAppInPurchaseRequest : NSObject
//特定于应用程序的用户标识符。可选的。
@property(nonatomic, copy, nullable) NSString *applicationUsername;

//用于指定要应用于此付款的折扣的相关数据。可选的。
@property(nonatomic, copy, nullable) SKPaymentDiscount *paymentDiscount API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2));

//与商店商定的标识符
@property(nonatomic, copy, nullable) NSString *productIdentifier;

//商品数量 默认值：1。必须至少为 1。
@property(nonatomic, assign) NSInteger quantity;

//与商店商定的付款请求数据
@property(nonatomic, copy, nullable) NSData *requestData;

//在沙箱中强制此付款的“询问购买”流程
@property(nonatomic, assign) BOOL simulatesAskToBuyInSandbox;

@end

NS_ASSUME_NONNULL_END
