//
//  PayAliPay.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import "PayAliPay.h"

@interface PayAliPay ()
@property(class, nonatomic, strong, readonly) PayAliPay *shared;
@end

@implementation PayAliPay

+(PayAliPay *)shared
{
    static dispatch_once_t onceToken;
    static PayAliPay *obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[PayAliPay alloc] init];
    });
    return obj;
}



/**
 在AppDelegate中的
 application:openURL:options:
 如果适配了SceneDelegate，需要处理则需要重写(该方法未测试)：
 scene:openURLContexts:
 执行此方法
 */
+ (void)handleOpenURL:(NSURL *)url
{
    if ([url.host isEqualToString:@"safepay"]) {
        // 支付跳转支付宝钱包进行支付，处理支付结果 --已经安装了APP，并且直接使用APP支付处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            [self handleResult:resultDic];
        }];

        // 授权跳转支付宝钱包进行支付，处理支付结果 --为安装app通过SDK中的web页面进行支付
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            [self handleResult:resultDic];
        }];
    }

    if ([url.host isEqualToString:@"platformapi"]) {
        // 授权跳转支付宝钱包进行支付，处理支付结果 --通过拦截网页中的支付url进行支付方式
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            [self handleResult:resultDic];
        }];
    }
}

+ (void)handleResult:(NSDictionary *)resultDic
{
    PayLog(@"AlipaySDK result = %@",resultDic);

    NSDictionary *userinfo = @{kNotificationUserInfoPayType:@(PayTypeAliPay),
                               kNotificationUserInfoResultData:resultDic
    };
    NSInteger code = [resultDic[@"resultStatus"] integerValue];
    if (code == 9000) {
        // 发通知带出支付成功结果
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNamePaySuccess object:nil userInfo:userinfo];
    } else {
        // 发通知带出支付失败结果
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNamePayFailed object:nil userInfo:userinfo];
    }
}



/**
 * 提交支付请求,拉起支付宝APP（或H5支付页面）
 * @param orderString 支付订单信息字串
 * @param appScheme 调用支付的app注册在info.plist中的scheme
 */
+ (void)payRequestOrder:(NSString *)orderString fromScheme:(NSString *)appScheme
{
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        //支付结果回调Block，用于wap支付结果回调（非跳转钱包支付）
        PayLog(@"H5 wap reslut");
        
        [self handleResult:resultDic];
    }];
}


/**
 *  提交支付请求,对 URL 进行拦截和支付转化
 *  @param url WK中拦截的支付URL(自动过滤，拦截url)
 *  @param appScheme 调用支付的app注册在info.plist中的scheme
 *  @param completionBlock 返回拦截后处理后的resultDic
 *  PS:https://opendocs.alipay.com/open/204/105695
 */
+ (BOOL)payWebRequestUrl:(NSString *)url fromScheme:(NSString *)appScheme callback:(void(^)(NSDictionary *resultDic))completionBlock
{
    return [[AlipaySDK defaultService] payInterceptorWithUrl:url fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        //拦截url
        PayLog(@"web Native reslut");
        [self handleResult:resultDic];

        if (completionBlock) {
            completionBlock(resultDic);
        }
    }];
}


@end
