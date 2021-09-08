//
//  PayAliPay.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import <Foundation/Foundation.h>
#import "PayBaseMacro.h"
#import <AlipaySDK/AlipaySDK.h>


NS_ASSUME_NONNULL_BEGIN

@interface PayAliPay : NSObject

/**
 在AppDelegate中的
 application:openURL:options:
 如果适配了SceneDelegate，需要处理则需要重写(该方法未测试)：
 scene:openURLContexts:
 执行此方法
 */
+ (void)handleOpenURL:(NSURL *)url;

/**
 * 提交支付请求,拉起支付宝APP（或H5支付页面）
 * @param orderString 支付订单信息字串
 * @param appScheme 调用支付的app注册在info.plist中的scheme
 */
+ (void)payRequestOrder:(NSString *)orderString fromScheme:(NSString *)appScheme;

/**
 *  提交支付请求,对 URL 进行拦截和支付转化
 *  @param url WK中拦截的支付URL(自动过滤，拦截url)
 *  @param appScheme 调用支付的app注册在info.plist中的scheme
 *  @param completionBlock 返回拦截后处理后的resultDic
 *  PS:https://opendocs.alipay.com/open/204/105695
 */
+ (BOOL)payWebRequestUrl:(NSString *)url fromScheme:(NSString *)appScheme callback:(void(^)(NSDictionary *resultDic))completionBlock;

@end


NS_ASSUME_NONNULL_END
