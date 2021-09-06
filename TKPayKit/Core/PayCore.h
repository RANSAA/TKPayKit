//
//  PayCore.h
//  TKPayKitDemo
//
//  Created by PC on 2021/9/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *kNotificationNamePaySuccess;//支付成功
extern NSString *kNotificationNamePayFailed;//支付失败
extern NSString *kNotificationUserInfoPayType;//通知userinfo.key，支付类型

/**支付类型 */
typedef NS_ENUM(NSInteger, PayType){
    PayTypeWeiXin = 0,
    PayTypeAli
};

@interface PayCore : NSObject

@end

NS_ASSUME_NONNULL_END
