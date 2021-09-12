//
//  PayBaseMacro.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


extern NSString *kNotificationNamePaySuccess;//支付成功
extern NSString *kNotificationNamePayFailed;//支付失败

extern NSString *kNotificationUserInfoPayType;//通知userinfo.key，支付类型,区分使用的那种支付方式
extern NSString *kNotificationUserInfoResultDic;//通知userinfo.key，支付结果(可为空)，类型：NSDictionary

/**支付类型 */
typedef NS_ENUM(NSInteger, PayType){
    PayTypeWeChat = 0,      //微信
    PayTypeAliPay,           //支付宝
    PayTypeApplePay,        //Aappl Pay
    PayTypeAppInPurchase,       //App In Purchase 内购
};


//BUG字符串是否输出t日志
#ifdef DEBUG
//#define PayLog(...) NSLog(__VA_ARGS__)
#define PayLog(FORMAT, ...) fprintf(stderr,"function:%s line:%d content:   %s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define PayLog(FORMAT, ...) nil
#endif




@interface PayBaseMacro : NSObject


@end

NS_ASSUME_NONNULL_END
