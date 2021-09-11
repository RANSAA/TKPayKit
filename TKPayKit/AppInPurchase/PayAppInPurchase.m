//
//  PayAppInPurchase.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/7.
//

#import "PayAppInPurchase.h"
#import <StoreKit/StoreKit.h>

@interface PayAppInPurchase () <SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property(nonatomic, assign) BOOL isObserver;
@property(nonatomic, assign) NSUInteger quantity;//商品数量 default = 1
@property(nonatomic, assign) NSInteger type;

@property(class, nonatomic, strong, readonly) PayAppInPurchase *shared;
@end

@implementation PayAppInPurchase

+(PayAppInPurchase *)shared
{
    static dispatch_once_t onceToken;
    static PayAppInPurchase *obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[PayAppInPurchase alloc] init];
    });
    return obj;
}

static NSInteger _verifyType = 0;
+ (void)setVerifyType:(NSInteger)verifyType{
    _verifyType = verifyType;
}
+ (NSInteger)verifyType{
    return _verifyType;
}

static NSString* _userID = @"unknown";
+(void)setUserID:(NSString *)userID{
    if (userID.length < 1) {
        _userID = @"unknown";
    }else{
        _userID = userID;
    }
}
+ (NSString *)userID{
    return _userID;
}

static NSString* _password = nil;
+ (void)setPassword:(NSString *)password{
    _password = password;
}
+ (NSString *)password{
    return _password;
}

static BOOL _excludeOldTransactions = NO;
+ (void)setExcludeOldTransactions:(BOOL)excludeOldTransactions
{
    _excludeOldTransactions = excludeOldTransactions;
}
+ (BOOL)excludeOldTransactions{
    return _excludeOldTransactions;;
}


- (void)dealloc
{
    [self removeStoreObserver];
}

- (void)addStoreObserver
{
    if (!_isObserver) {
        _isObserver = YES;
        [SKPaymentQueue.defaultQueue addTransactionObserver:self];
     }
}

- (void)removeStoreObserver
{
    if (_isObserver) {
        _isObserver = NO;
        [SKPaymentQueue.defaultQueue removeTransactionObserver:self];
    }
}

#pragma mark 注册区域
/** 注册Store */
+ (void)registerApp
{
    if ([SKPaymentQueue canMakePayments]) {
        [self.shared addStoreObserver];
    }else{
        PayLog(@"请开启In App Purchase功能。");
    }
}

/**

 PS:交易请求之前，还需要检查是否还有缓存未验证的交易记录
 */
+ (void)payPequestProducts:(NSArray<NSString *> *)products quantity:(NSUInteger)quantity completion:(void(^)(BOOL success, NSString* msg))completion
{
    NSString *msg;
    if ([SKPaymentQueue canMakePayments]) {
        if (products.count>0) {
            self.shared.quantity = quantity<1?1:quantity;
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:products]];
            request.delegate = self.shared;
            [request start];

            if (completion) {
                msg = @"In App Purchase 开始请求...";
                PayLog(@"%@",msg);
                completion(YES,msg);
            }
        }else{
            if (completion) {
                msg = @"error: Product id 不能为空";
                PayLog(@"%@",msg);
                completion(NO,msg);
            }
        }
    }else{
        if (completion) {
            msg = @"error: 请开启In App Purchase功能。";
            PayLog(@"%@",msg);
            completion(NO,msg);
        }
    }
}


#pragma mark Pay Success or Pay Failed notifaction


#pragma mark SKProductsRequestDelegate

//接收到产品的返回信息,然后用返回的商品信息进行发起购买请求
//目前无法测试
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *myProduct = response.products;
    if (myProduct.count == 0) {
        PayLog(@"没有查询到商品，支付失败");
        PayLog(@"无效的Product ID列表：%@",response.invalidProductIdentifiers);
        return;
    }
    PayLog(@"产品Product ID列表：%@",response.products);

    // populate UI
    for(SKProduct *product in myProduct){
        PayLog(@"product info");
        PayLog(@"SKProduct 描述信息%@", [product description]);
        PayLog(@"产品标题 %@" , product.localizedTitle);
        PayLog(@"产品描述信息: %@" , product.localizedDescription);
        PayLog(@"价格: %@" , product.price);
        PayLog(@"Product id: %@" , product.productIdentifier);

//        // 11.如果后台消费条目的ID与我这里需要请求的一样（用于确保订单的正确性）
//        if([product.productIdentifier isEqualToString:@"com.czchat.CZChat01"]){
//            requestProduct = product;
//        }
    }

    //发送购买请求
    SKProduct *product = myProduct.firstObject;//需要验证product id的一致性
    if (self.quantity == 1) {
        SKPayment * payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else{
        SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:product];
        payment.quantity = self.quantity;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    PayLog(@"请求失败，支付失败");
}

//反馈请求的产品信息结束后
- (void)requestDidFinish:(SKRequest *)request
{
    PayLog(@"一次支付请求完成");
}



#pragma mark SKPaymentTransactionObserver

//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for(SKPaymentTransaction *tran in transactions){
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased://交易完成
                PayLog(@"交易完成");
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                PayLog(@"恢复购买成功");
                [self restoreTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                PayLog(@"交易取消或失败");
                [self failedTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                PayLog(@"商品添加进列表");
                break;
            case SKPaymentTransactionStateDeferred:
                PayLog(@"交易进行中，等待外部操作。。。");
                break;
            default:
                break;
        }
    }
}



// 交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if(transaction.error.code != SKErrorPaymentCancelled) {
        PayLog(@"购买失败");
    } else {
        PayLog(@"用户取消交易");
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

}


// 交易完成
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [self recordTransaction:transaction];
    [self verifyReceiptWithTransaction:transaction];

//    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


// 恢复购买
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    [self recordTransaction:transaction];
    [self verifyReceiptWithTransaction:transaction];

//    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


#pragma mark 缓存记录
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
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        NSDate *transactionDate         = transaction.transactionDate;
        NSString *transactionIdentifier = transaction.transactionIdentifier;

        NSString *key = [NSString stringWithFormat:@"%@+%@",transactionIdentifier,transactionDate];
        NSDictionary *info = @{@"type":@(self.type),
                               @"key":key,
                               @"transactionIdentifier":transactionIdentifier,
                               @"transactionDate":transactionDate,
                               @"receiptData":receiptData
        };
        [PayAppInPurchase addUserDefaultWithKey:key info:info];
    }
}

//移出支付操作完成的凭证缓存数据
- (void)removeTransaction:(SKPaymentTransaction *)transaction
{
    NSString *transactionIdentifier = transaction.transactionIdentifier;
    NSDate *transactionDate         = transaction.transactionDate;
    NSString *key = [NSString stringWithFormat:@"%@+%@",transactionIdentifier,transactionDate];
    [PayAppInPurchase deleteUserDefaultWithKey:key];
}

+ (NSDictionary *)addUserDefaultWithKey:(NSString *)key info:(NSDictionary *)info
{
    NSString *userKey = PayAppInPurchase.userID;
    NSUserDefaults *user = [self.shared receiptDefaults];
    NSDictionary *userDic = [user valueForKey:userKey];
    if (!userDic) {
        userDic = @{};
    }
    NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:userDic];
    [mDic setValue:info forKey:key];
    [user setValue:mDic forKey:userKey];
    [user synchronize];

    return info;
}

+ (NSString *)deleteUserDefaultWithKey:(NSString *)cacheKey
{
    NSString *userKey = PayAppInPurchase.userID;
    NSUserDefaults *user = [self.shared receiptDefaults];
    NSDictionary *userDic = [user valueForKey:userKey];
    if (user) {
        NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:userDic];
        [mDic removeObjectForKey:cacheKey];
        [user setValue:mDic forKey:userKey];
        [user synchronize];
    }
    return cacheKey;
}


/**
 检测缓存的未验证的交易凭证,如果有回调自行验证

 */
+ (void)checkVerifyPeceiptCompletion:(void(^)(BOOL verify, NSArray<NSDictionary *>* list))completion
{
    NSUserDefaults *user = [self.shared receiptDefaults];
    NSDictionary *dic = [user valueForKey:PayAppInPurchase.userID];
    if (dic.count > 0) {
        NSArray *allValues = dic.allValues;
        if (PayAppInPurchase.verifyType == 0) {//Apple内部验证
            //一般一会有一个，这儿，直接循环处理，外部最好依次处理
            for (NSDictionary *dic in allValues) {
                NSString *key = dic[@"key"];
                NSData *receiptData = dic[@"receiptData"];
                [self.shared verifyReceiptData:receiptData completion:^(NSInteger status) {
                    if (status == 1) {
                        PayLog(@"成功。凭证有效");
                        [self deleteUserDefaultWithKey:key];
                    }else if (status == 0){
                        PayLog(@"失败，凭证无效");
                        [self deleteUserDefaultWithKey:key];
                    }else{
                        PayLog(@"网络错误，需要重新验证");
                    }
                }];
            }
        }else{
            if (completion) {
                completion(YES,allValues);
            }
        }
    }
}



//交易请求之前，还需要检查是否还有缓存未验证的交易记录


#pragma mark 验证交易凭证
//处理交易数据并验证
//⚠️：验证时需要将数据缓存在本地，防止网络请求失败，APP中断等问题 （还没有处理）
- (void)verifyReceiptWithTransaction:(SKPaymentTransaction *)transaction
{
    NSString * productIdentifier = transaction.payment.productIdentifier;
    PayLog(@"交易完成Identifier %@", productIdentifier);

    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    // 从沙盒中获取到购买凭据(原始数据)
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
//    NSString * receiptStr = [[NSString alloc]initWithData:receiptData encoding:NSUTF8StringEncoding];

    if (PayAppInPurchase.verifyType == 0) {//直接通过Apple验证
        [self verifyReceiptData:receiptData completion:^(NSInteger status) {
            if (status == 1 ) {
                PayLog(@"成功。凭证有效");
            }else if(status == 0){
                PayLog(@"失败，凭证无效");
            }else{
                PayLog(@"网络错误，需要重新验证");
            }
        }];
    }else{//直接自己的服务器验证

    }

    //不管交易成功还是失败，Apple Store支付这一步已经完成，只会存在该条交易验证与否，判断该交易是否有效而已。
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];


//    if (PayAppInPurchase.verifyType == 0) {//直接通过Apple验证
//        //处理凭证类型
//        NSString *environment= [self environmentForReceipt:receiptStr];
//        //凭证base64编码
//        NSString *encodeStr = [receiptData base64EncodedStringWithOptions:kNilOptions];
//        NSString *sendString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
//        NSLog(@"_____%@",sendString);
//        NSURL *StoreURL=nil;
//        if ([environment isEqualToString:@"environment=Sandbox"]) {
//            StoreURL= [[NSURL alloc] initWithString: @"https://sandbox.itunes.apple.com/verifyReceipt"];
//        }else{
//            StoreURL= [[NSURL alloc] initWithString: @"https://buy.itunes.apple.com/verifyReceipt"];
//        }
//        //这个二进制数据由服务器进行验证；zl
//        NSData *postData = [NSData dataWithBytes:[sendString UTF8String] length:[sendString length]];
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:StoreURL];
//        [request setHTTPMethod:@"POST"];
//        [request setTimeoutInterval:50.0];//120.0---50.0zl
//        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
//        [request setHTTPBody:postData];
//
//        //验证时需要将数据缓存在本地，防止网络请求失败，APP中断等问题
//        //开始请求
//        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            if (error) {
//                PayLog(@"验证购买过程中发生错误，错误信息：%@",error.localizedDescription);
//            }else{
//                NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//                PayLog(@"App In Pruchase verify data:%@",dic);
//                NSInteger status = [dic[@"status"] integerValue];
//                [self machVerifyCode:status];
//                if (status == 0) {
//                    PayLog(@"凭证有效，验证成功，即整个支付操作成功！");
//                    //处理验证结果逻辑，并把操作发送给服务端
//                    [self sendApplePayDataToServerRequsetWith:transaction];
//                }else{
//                    PayLog(@"凭证无效，验证失败，即整个支付操作失败");
//                }
//            }
//
//        }];
//        [task resume];
//
//    }else{//向自己的服务器验证购买凭证
//        //回调传送到外部自己的服务其验证处理处理receiptData
//        //
//    }

//    //不管交易成功还是失败，Apple Store支付这一步已经完成，只会存在该条交易验证与否，判断该交易是否有效而已。
//    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

/**
 验证支付凭证数据
 receiptData：凭证数据
 completion：验证完毕后回调
 status:凭证验证状态
        0：失败，凭证无效
        1：成功。凭证有效
        2：网络错误，需要重新验证
 */
- (void)verifyReceiptData:(NSData *)receiptData completion:(void(^)(NSInteger status))completion
{
    if (!receiptData) {
        PayLog(@"receiptData数据为空，验证失败");
        if (completion) {
            completion(0);
        }
        return;
    }
    NSString * receiptStr = [[NSString alloc]initWithData:receiptData encoding:NSUTF8StringEncoding];
    //处理凭证类型
    NSString *environment= [self environmentForReceipt:receiptStr];
    //凭证base64编码
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:kNilOptions];

//    NSString *sendString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSMutableDictionary *mBody = @{@"receipt-data":encodeStr}.mutableCopy;
    [mBody addEntriesFromDictionary:@{@"exclude-old-transactions":@(PayAppInPurchase.excludeOldTransactions)}];
    if (PayAppInPurchase.password) {
        [mBody addEntriesFromDictionary:@{@"password":PayAppInPurchase.password}];
    }
    NSData* mData = [NSJSONSerialization dataWithJSONObject:mBody options:kNilOptions error:nil];
    NSString *sendString = [[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding];
    PayLog(@"requestBody：%@",sendString);

    NSURL *StoreURL=nil;
    if ([environment isEqualToString:@"environment=Sandbox"]) {
        StoreURL= [[NSURL alloc] initWithString: @"https://sandbox.itunes.apple.com/verifyReceipt"];
    }else{
        StoreURL= [[NSURL alloc] initWithString: @"https://buy.itunes.apple.com/verifyReceipt"];
    }
    //这个二进制数据由服务器进行验证；zl
    NSData *postData = [NSData dataWithBytes:[sendString UTF8String] length:[sendString length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:StoreURL];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:50.0];//120.0---50.0zl
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPBody:postData];

    //验证时需要将数据缓存在本地，防止网络请求失败，APP中断等问题
    //开始请求
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            PayLog(@"网络错误，需要重新验证\n验证购买过程中发生错误，错误信息：%@",error.localizedDescription);
            if (completion) {
                completion(2);
            }
        }else{
            NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            PayLog(@"App In Pruchase verify data:%@",dic);
            NSInteger status = [dic[@"status"] integerValue];
            [self machVerifyCode:status];
            
            BOOL verifyStatus = status==0?YES:NO;
            NSInteger code = verifyStatus?1:0;
            NSString *msg = verifyStatus?@"成功。凭证有效，即整个支付操作成功！":@"失败，凭证无效，即整个支付操作失败";
            PayLog(@"%@",msg);
            if (completion) {
                completion(code);
            }
        }
    }];
    [task resume];
}


/**
 Receipt Validation Programming Guide:   https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/validating_receipts_with_the_app_store#//apple_ref/doc/uid/TP40010573-CH104-SW1
 verifyReceipt: https://developer.apple.com/documentation/appstorereceipts/verifyreceipt
 requestBody:   https://developer.apple.com/documentation/appstorereceipts/requestbody
 responseBody:  https://developer.apple.com/documentation/appstorereceipts/responsebody
 expiration_intent: https://developer.apple.com/documentation/appstorereceipts/expiration_intent

 */
- (void)machVerifyCode:(NSInteger) status
{
    NSString *message = @"";
    switch (status) {
        case 0:
            message = @"Success: The receipt as a whole is valid.";
            break;
        case 21000:
            message = @"Error: The App Store could not read the JSON object you provided.";
            break;
        case 21002:
            message = @"Error: The data in the receipt-data property was malformed or missing.";
            break;
        case 21003:
            message = @"Error: The receipt could not be authenticated.";
            break;
        case 21004:
            message = @"Error: The shared secret you provided does not match the shared secret on file for your account.";
            break;
        case 21005:
            message = @"Error: The receipt server is not currently available.";
            break;
        case 21006:
            message = @"Error: This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.";
            break;
        case 21007:
            message = @"Error: This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.";
            break;
        case 21008:
            message = @"Error: This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.";
            break;
        case 21010:
            message = @"Error: This receipt could not be authorized. Treat this the same as if a purchase was never made.";
            break;
        default: /* 21100-21199 */
            message = @"Error: Internal data access error.";
            break;
    }
}

//凭证验证成功之后向服务器发送其它的逻辑处理结果
- (void)sendApplePayDataToServerRequsetWith:(SKPaymentTransaction *)transaction
{
    //1.移出缓存的凭证数据
    [self removeTransaction:transaction];

    //2.处理支付成功之后的逻辑，并将结果发送给服务器
}




-(NSString * )environmentForReceipt:(NSString * )str
{
    str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray * arr = [str componentsSeparatedByString:@";"];

    //存储收据环境的变量
    NSString * environment = arr[2];
    return environment;
}

@end
