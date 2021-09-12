//
//  AppDelegate.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/6.
//

#import "AppDelegate.h"
#import "TKPayKit.h"
#import <StoreKit/StoreKit.h>
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [PayWeChat startLog];
    [PayWeChat registerApp:@"34" universalLink:@"353"];
    [PayWeChat checkEnv];


    [PayAppInPurchase registerApp];
    [PayAppInPurchase checkRecordReceiptDataWithCompletion:^(BOOL isVerify, NSArray<NSDictionary *> * _Nullable list) {
        if (isVerify) {
            for (NSDictionary *dic in list) {
                NSString *key = dic[@"key"];
                NSInteger type = [dic[@"type"] integerValue];
                NSString *transactionIdentifier = dic[@"transactionIdentifier"];
                NSDate *transactionDate = dic[@"transactionDate"];
                NSData *receiptData = dic[@"receiptData"];
                //依次验证凭证,或者使用自己的服务器验证
                [PayAppInPurchase verifyReceiptData:receiptData completion:^(NSInteger status) {
                    if (status == 0) {
                        PayLog(@"验证失败");
                        [PayAppInPurchase removeRecordReceiptDataWithKey:key];
                    }else if (status == 1){
                        PayLog(@"验证失败");
                        [PayAppInPurchase removeRecordReceiptDataWithKey:key];
                    }else{
                        PayLog(@"网络错误，需要从新验证");
                    }
                }];
            }
        }
    }];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    [PayAliPay handleOpenURL:url];
    return [PayWeChat handleOpenURL:url];
}


- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    return [PayWeChat handleOpenUniversalLink:userActivity];
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)){
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

//记录交易记录
- (NSUserDefaults *)receiptDefaults
{
    NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName:@"AppInPurchaseTransaction"];
    return user;
}

//记录交易记录
- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    NSString *path = [[NSBundle.mainBundle appStoreReceiptURL] path];
    if ([NSFileManager.defaultManager fileExistsAtPath:path] ) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *transactionReceipt      = [NSData dataWithContentsOfURL:receiptURL];
        NSDate *transactionDate         = transaction.transactionDate;
        NSString *transactionIdentifier = transaction.transactionIdentifier;
        NSDictionary *info = @{@"type":@(1),
                               @"transactionIdentifier":transactionIdentifier,
                               @"transactionDate":transactionDate,
                               @"transactionReceipt":transactionReceipt
        };
        NSString *key = [NSString stringWithFormat:@"%@+%@",transactionIdentifier,transactionDate];
        [self addUserDefaultWithKey:key info:info];
    }
}

//移出支付操作完成的凭证缓存数据
- (void)removeTransaction:(SKPaymentTransaction *)transaction
{
    NSString *transactionIdentifier = transaction.transactionIdentifier;
    NSDate *transactionDate         = transaction.transactionDate;
    NSString *key = [NSString stringWithFormat:@"%@+%@",transactionIdentifier,transactionDate];
    [self deleteUserDefaultWithKey:key];
}

- (void)addUserDefaultWithKey:(NSString *)key info:(NSDictionary *)info
{
    NSString *userKey = PayAppInPurchase.userID;
    NSUserDefaults *user = [self receiptDefaults];
    NSDictionary *userDic = [user valueForKey:userKey];
    if (!userDic) {
        userDic = @{};
    }
    NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:userDic];
    [mDic setValue:info forKey:key];
    [user setValue:mDic forKey:userKey];
    [user synchronize];
}

- (void)deleteUserDefaultWithKey:(NSString *)key
{
    NSString *userKey = PayAppInPurchase.userID;
    NSUserDefaults *user = [self receiptDefaults];
    NSDictionary *userDic = [user valueForKey:userKey];
    if (user) {
        NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:userDic];
        [mDic removeObjectForKey:key];
        [user setValue:mDic forKey:userKey];
        [user synchronize];
    }
}

@end
