//
//  PayWeChat.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import <Foundation/Foundation.h>
#import "PayBaseMacro.h"
#import <WXApi.h>



NS_ASSUME_NONNULL_BEGIN

@interface PayWeChat : NSObject <WXApiDelegate>


/** 开启日志,在注册之前执行 */
+ (void)startLog;

/**
 * 注册
 * @param appid 微信开发者ID
 * @param universalLink 微信开发者Universal Link
 * 例如：Universal Link: @"applinks:baidu.com"
 */
+ (BOOL)registerApp:(NSString *)appid universalLink:(NSString *)universalLink;

/** 检查环境,在注册之后 */
+ (void)checkEnv;

/**
 在AppDelegate中的
 application:openURL:options:
 //低于iOS9(如果不需要可以不适配)
 //application:handleOpenURL:
 //application:openURL:sourceApplication:
 PS：如果适配了SceneDelegate则可能会调用(未测试)scene:openURLContexts:
 如果适配了SceneDelegate，需要处理则需要重写(该方法未测试)：
 scene:openURLContexts:
 执行此方法，并返回
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 在AppDelegate中的
 application:continueUserActivity:restorationHandler:
 如果适配了SceneDelegate，需要处理则需要重写(该方法未测试)：
 scene:continueUserActivity:
 执行此方法，并返回
 */
+ (BOOL)handleOpenUniversalLink:(NSUserActivity *)userActivity;


/** 提交支付请求*/
+ (void)payRequestReq:(NSDictionary *)request completion:(void(^)(BOOL success, NSString* msg))completion;




@end

NS_ASSUME_NONNULL_END
