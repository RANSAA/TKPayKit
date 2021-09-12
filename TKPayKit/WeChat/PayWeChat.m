//
//  PayWeChat.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import "PayWeChat.h"

@interface PayWeChat ()
@property(class, nonatomic, strong, readonly) PayWeChat *shared;
@end

@implementation PayWeChat

+(PayWeChat *)shared
{
    static dispatch_once_t onceToken;
    static PayWeChat *obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[PayWeChat alloc] init];
    });
    return obj;
}

/** 检查环境 */
+ (void)checkEnv
{
    //调用自检函数
    [WXApi checkUniversalLinkReady:^(WXULCheckStep step, WXCheckULStepResult* result) {
        PayLog(@"%@, %u, %@, %@", @(step), result.success, result.errorInfo, result.suggestion);
    }];
}

#pragma mark 注册区域
/** 开启日志,在注册之前执行 */
+ (void)startLog
{
    //在register之前打开log, 后续可以根据log排查问题
    [WXApi startLogByLevel:WXLogLevelDetail logBlock:^(NSString *log) {
        PayLog(@"WeChatSDK: %@", log);
    }];

}


/**
 * 注册
 * @param appid 微信开发者ID
 * @param universalLink 微信开发者Universal Link
 * 例如：Universal Link: @"applinks:baidu.com"
 */
+ (BOOL)registerApp:(NSString *)appid universalLink:(NSString *)universalLink
{
    return [WXApi registerApp:appid universalLink:universalLink];
}

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
+ (BOOL)handleOpenURL:(NSURL *)url
{
    return [WXApi handleOpenURL:url delegate:self.shared];
}


/**
 在AppDelegate中的
 application:continueUserActivity:restorationHandler:
 如果适配了SceneDelegate，需要处理则需要重写(该方法未测试)：
 scene:continueUserActivity:
 执行此方法，并返回
 */
+ (BOOL)handleOpenUniversalLink:(NSUserActivity *)userActivity
{
    return [WXApi handleOpenUniversalLink:userActivity delegate:self.shared];
}


#pragma mark 订单请求
+ (void)checkWXApi:(void(^)(BOOL success, NSString* msg))handle
{
    NSString *msg = nil;
    if ([WXApi isWXAppInstalled]) {
        if ([WXApi isWXAppSupportApi]) {
            msg = @"微信环境检测通过！";
            PayLog(@"%@",msg);
            handle(YES,msg);
        }else{
            msg = @"当前微信的版本不支持OpenApi，请下载最新版本的微信！";
            PayLog(@"%@",msg);
            handle(NO,msg);
        }
    }else{
        msg = @"请安装微信！";
        PayLog(@"%@",msg);
        handle(NO,msg);
    }
}


/** 提交支付请求*/
+ (void)payRequestReq:(NSDictionary *)request completion:(void(^)(BOOL success, NSString* msg))completion
{
    [self checkWXApi:^(BOOL success, NSString *msg) {
        if (success) {
            PayReq *req = [[PayReq alloc] init];
            req.partnerId = [request objectForKey:@"partnerId"];
            req.prepayId  = [request objectForKey:@"prepayId"];
            req.package   = [request objectForKey:@"packageValue"];
            req.nonceStr  = [request objectForKey:@"nonceStr"];
            req.timeStamp = [[request objectForKey:@"timeStamp"] intValue];
            req.sign      = [request objectForKey:@"sign"];
            [WXApi sendReq:req completion:^(BOOL success) {
                NSString *msg = success ? @"请求成功" : @"请求失败";
                completion(success,msg);
            }];
        }else{
            completion(success,msg);
        }
    }];
}



#pragma mark WXApiDelegate

////微信向客户端发送一个请求
//- (void)onReq:(BaseReq *)req
//{
//    if([req isKindOfClass:[GetMessageFromWXReq class]])
//    {
//        // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
//        NSString *strTitle = [NSString stringWithFormat:@"微信请求App提供内容"];
//        NSString *strMsg = @"微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信";
//    }else if([req isKindOfClass:[ShowMessageFromWXReq class]]){
//        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
//        WXMediaMessage *msg = temp.message;
//        //显示微信传过来的内容
//        WXAppExtendObject *obj = msg.mediaObject;
//    }
//    else if([req isKindOfClass:[LaunchFromWXReq class]])
//    {
//        //从微信启动App
//        NSString *strTitle = [NSString stringWithFormat:@"从微信启动"];
//        NSString *strMsg = @"这是从微信启动的消息";
//    }
//}


//支付结果回调
- (void)onResp:(BaseResp *)resp
{
    //微信支付结果
    if ([resp isKindOfClass:[PayResp class]]) {
        PayResp *tmpResp = (PayResp *)resp;
        NSString *msg = [NSString stringWithFormat:@"支付结果: errCode = %d, retstr = %@", tmpResp.errCode, tmpResp.errStr];
        PayLog(@"WeiXin Pay msg:%@",msg);

        NSArray *keys = @[@"returnKey",@"errCode",@"errStr",@"type"];
        NSDictionary *resultDic = [tmpResp dictionaryWithValuesForKeys:keys];
        NSDictionary *userinfo = @{kNotificationUserInfoPayType:@(PayTypeWeChat),
                                   kNotificationUserInfoResultDic:resultDic

        };
        switch (tmpResp.errCode) {
            case WXSuccess:
                [self paySuccessWithResult:userinfo];
                break;
            default:
                [self payFailedWithResult:userinfo];
                break;
        }
    }
}


- (void)paySuccessWithResult:(NSDictionary *)userInfo
{
    //服务器端查询支付通知或查询API返回的结果再提示成功
    //后续再向服务器添加一个APP当前支付转态回调接口的请求
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNamePaySuccess object:nil userInfo:userInfo];
}

- (void)payFailedWithResult:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNamePayFailed object:nil userInfo:userInfo];
}

@end
