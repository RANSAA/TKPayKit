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
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, strong, nullable) PayAppInPurchaseRequest *req;

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
 * 提交App In Purchase支付请求
 * products：需要支付的商品productID列表
 * req:附加的商品信息，如商品数量. 可选
 * type：自定义的商品类型标注，会在checkRecordReceiptDataWithCompletion:中的list.dic.type中返回
 * @completion
 * success：请求是否提交成功
 * msg：消息
 */
+ (void)payPequestProducts:(NSArray<NSString *> *)products req:(nullable PayAppInPurchaseRequest *)req type:(NSInteger)type completion:(void(^)(BOOL success, NSString* msg))completion
{
    NSString *msg;
    if ([SKPaymentQueue canMakePayments]) {
        if (products.count>0) {
            self.shared.req = req;
            self.shared.type = type;
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:products]];
            request.delegate = self.shared;
            [request start];

            msg = @"In App Purchase 开始请求...";
            PayLog(@"%@",msg);
            if (completion) {
                completion(YES,msg);
            }
        }else{
            msg = @"error: Product id 不能为空";
            PayLog(@"%@",msg);
            if (completion) {
                completion(NO,msg);
            }
        }
    }else{
        msg = @"error: 请开启In App Purchase功能。";
        PayLog(@"%@",msg);
        if (completion) {
            completion(NO,msg);
        }
    }
}


/**
 * 恢复购买请求提交
 * username：特定于应用程序的用户标识符。可选的。
 * @completion
 * success：请求是否提交成功
 * msg：消息
 */
+ (void)payRequestRestoresWithApplicationUsername:(nullable NSString *)username completion:(void(^)(BOOL success, NSString* msg))completion
{
    NSString *msg;
    if ([SKPaymentQueue canMakePayments]) {
        if (username) {
            [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:username];
        }else{
            [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        }
        msg = @"In App Purchase 恢复购买 开始请求...";
        PayLog(@"%@",msg);
        if (completion) {
            completion(YES,msg);
        }
    }else{
        msg = @"error: 请开启In App Purchase功能。";
        PayLog(@"%@",msg);
        if (completion) {
            completion(NO,msg);
        }
    }
}



#pragma mark SKProductsRequestDelegate

/**
 * 接收到产品的返回信息,然后用返回的商品信息进行发起购买请求
 * 状态：当前还没有测试
 * PS：目前还不知道该方法返回的时所有productID信息，还是当前请求的product
 * 如果是当前请求的productID信息，直接提交对应payment product即可；
 * 如果是所有的productID信息，则需要提取出与当前请求一致的productID
 */
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    if (products.count == 0) {

        NSString *msg = @"支付失败，没有查询到商品";
        msg = [NSString stringWithFormat:@"%@\n无效的Product ID列表：%@",msg,response.invalidProductIdentifiers];
        PayLog(@"%@",msg);
        NSDictionary *info = @{@"msg":msg};
        [self payFailedNotifaction:info];
        return;
    }
    PayLog(@"产品Product ID列表：%@",response.products);

    // populate UI
    SKProduct *payProduct = nil;
    for(SKProduct *product in products){
        PayLog(@"product info");
        PayLog(@"SKProduct 描述信息%@", [product description]);
        PayLog(@"产品标题 %@" , product.localizedTitle);
        PayLog(@"产品描述信息: %@" , product.localizedDescription);
        PayLog(@"价格: %@" , product.price);
        PayLog(@"Product id: %@" , product.productIdentifier);

//        // 如果后台消费条目的ID与我这里需要请求的一样（用于确保订单的正确性）
//        if([product.productIdentifier isEqualToString:@"com.czchat.CZChat01"]){
//            payProduct = product;
//        }
    }

    //发送购买请求
    payProduct = products.firstObject;//需要验证product id的一致性
    if (self.req) {
        SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:payProduct];
        payment.quantity = self.req.quantity;
        if (self.req.applicationUsername) {
            payment.applicationUsername = self.req.applicationUsername;
        }
        if (self.req.productIdentifier) {
            payment.productIdentifier = self.req.productIdentifier;
        }
        if (self.req.applicationUsername) {
            payment.requestData = self.req.requestData;
        }
        if (self.req.applicationUsername) {
            payment.simulatesAskToBuyInSandbox = self.req.simulatesAskToBuyInSandbox;
        }
        if (@available(iOS 12.2, *)) {
            if (self.req.paymentDiscount) {
                payment.paymentDiscount = self.req.paymentDiscount;
            }
        }
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else{
        SKPayment * payment = [SKPayment paymentWithProduct:payProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    PayLog(@"支付失败，支付请求错误");
    NSString *msg = @"支付失败，支付请求错误";
    NSDictionary *info = @{@"msg":msg,@"error":error};
    [self payFailedNotifaction:info];
}

//反馈请求的产品信息结束后
- (void)requestDidFinish:(SKRequest *)request
{
    PayLog(@"一次支付请求完成");
    self.req = nil;
    self.type = 0;
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
                PayLog(@"已经购买过商品-恢复购买成功");
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

/**
 * 恢复购买完成时
 * 函数中添加如下逻辑，用一个NSMutableArray来存储苹果回调过来给我们已经购买过的非消耗品的商品信息：
 * test
 */
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSMutableArray *purchasedItemIDs = [[NSMutableArray alloc] init];
    PayLog(@"恢复购买未处理。。。");
    PayLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        NSString *productID = transaction.payment.productIdentifier;
        [purchasedItemIDs addObject:productID];
        NSLog(@"purchasedItemIDs:%@",purchasedItemIDs);
    }
}

//恢复购买失败
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)er
{

}

#pragma mark 支付成功/失败时发送通知
- (void)paySuccessNotifaction:(NSDictionary *)receiptDic
{
    NSMutableDictionary *userInfo = @{kNotificationUserInfoPayType:@(PayTypeAppInPurchase)}.mutableCopy;
    if (receiptDic) {
        [userInfo addEntriesFromDictionary:@{kNotificationUserInfoResultDic:receiptDic}];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNamePaySuccess object:nil userInfo:userInfo];
}

- (void)payFailedNotifaction:(NSDictionary *)info
{
    NSMutableDictionary *userInfo = @{kNotificationUserInfoPayType:@(PayTypeAppInPurchase),
                                      kNotificationUserInfoResultDic:info
    }.mutableCopy;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNamePayFailed object:nil userInfo:userInfo];
}


#pragma mark 交易状态处理

// 交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSString *msg = nil;
    if(transaction.error.code != SKErrorPaymentCancelled) {
        PayLog(@"支付失败，购买失败");
        msg = @"支付失败，购买失败";
    } else {
        PayLog(@"支付失败，用户取消交易");
        msg = @"支付失败，用户取消交易";
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];


    NSDictionary *info = @{@"msg":msg,@"error":transaction.error};
    [self payFailedNotifaction:info];
}


/**
 * 交易完成
 * 外部接收到支付成功通知之后，验证交易凭证
 */
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    //缓存交易记录
    NSDictionary *receiptDic = [self recordTransaction:transaction];
    //完成交易凭证
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

    //notifaction
    [self paySuccessNotifaction:receiptDic];
}


/**
 * 恢复购买--非消耗型
 * 验证：外部接收到支付成功通知之后，验证交易凭证--这儿不明确是否需要验证处理，
 * PS:如果从transaction中拿不到交易凭证，那么需要使用transaction.downloads从apple服务器下载凭证再，进行处理。
 *    并且验证的凭证数据不能再从checkRecordReceiptDataWithCompletion：中回调获取
 *    目前还没有验证是否会有这种情况出现
 */
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    // Re-download the Apple-hosted content, then finish the transaction
    // and remove the product identifier from the array of product IDs.

    //缓存交易记录
    NSDictionary *receiptDic = [self recordTransaction:transaction];//transaction.originalTransaction
    //完成交易凭证
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

    //notifaction
    [self paySuccessNotifaction:receiptDic];
}


#pragma mark 缓存交易记录
- (NSUserDefaults *)receiptDefaults
{
    NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName:@"AppInPurchaseTransaction"];
    return user;
}

//记录交易记录
- (nullable NSDictionary *)recordTransaction:(SKPaymentTransaction *)transaction
{
    NSString *path = [[NSBundle.mainBundle appStoreReceiptURL] path];
    if ([NSFileManager.defaultManager fileExistsAtPath:path] ) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        NSDate *transactionDate         = transaction.transactionDate;
        NSString *transactionIdentifier = transaction.transactionIdentifier;

        NSString *key = [NSString stringWithFormat:@"%@+%@",transactionIdentifier,transactionDate];
        NSDictionary *receiptDic = @{@"type":@(self.type),
                               @"key":key,
                               @"transactionIdentifier":transactionIdentifier,
                               @"transactionDate":transactionDate,
                               @"receiptData":receiptData
        };
        [PayAppInPurchase addRecordReceiptDataWithKey:key receiptDic:receiptDic];
        return receiptDic;
    }
    return nil;
}

/**
 * 添加交易收据凭证到缓存列表
 * key：记录标识key
 * receiptDic：具体的凭证数据
 */
+ (NSDictionary *)addRecordReceiptDataWithKey:(NSString *)key receiptDic:(NSDictionary *)receiptDic
{
    NSString *userKey = PayAppInPurchase.userID;
    NSUserDefaults *user = [self.shared receiptDefaults];
    NSDictionary *userDic = [user valueForKey:userKey];
    if (!userDic) {
        userDic = @{};
    }
    NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:userDic];
    [mDic setValue:receiptDic forKey:key];
    [user setValue:mDic forKey:userKey];
    [user synchronize];

    return receiptDic;
}

/**
 * 移出支付凭证记录缓存
 * key:记录唯一标识，从checkRecordReceiptDataWithCompletion:回调中的list.dic.key中获取
 */
+ (NSString *)removeRecordReceiptDataWithKey:(NSString *)key
{
    NSString *userKey = PayAppInPurchase.userID;
    NSUserDefaults *user = [self.shared receiptDefaults];
    NSDictionary *userDic = [user valueForKey:userKey];
    if (user && userDic) {
        NSDictionary *receiptDic = nil;//对应的收据凭证数据
        NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:userDic];
        receiptDic = [mDic valueForKey:key];
        [mDic removeObjectForKey:key];
        [user setValue:mDic forKey:userKey];
        [user synchronize];
        //
        NSDate *transactionDate = receiptDic[@"transactionDate"];
        NSString *transactionIdentifier = receiptDic[@"transactionIdentifier"];
        for (SKPaymentTransaction *transaction in SKPaymentQueue.defaultQueue.transactions) {
            if ([transaction.transactionDate isEqualToDate:transactionDate] && [transactionIdentifier isEqualToString:transaction.transactionIdentifier]) {
                [SKPaymentQueue.defaultQueue finishTransaction:transaction];
            }
        }
    }
    return key;
}


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
+ (void)checkRecordReceiptDataWithCompletion:(void(^)(BOOL isVerify,  NSArray<NSDictionary *>* _Nullable list))completion
{
    NSUserDefaults *user = [self.shared receiptDefaults];
    NSDictionary *dic = [user valueForKey:PayAppInPurchase.userID];
    if (dic.count>0) {
        NSArray *allValues = dic.allValues;
        if (completion) {
            completion(YES,allValues);
        }
    }else{
        if (completion) {
            completion(NO,nil);
        }
    }
}



/**
 * 验证支付凭证数据，直接在App中向apple服务器发送验证信息
 * receiptData：凭证数据
 * @completion：验证完毕后回调
 * status:凭证验证状态
 *        0：失败，凭证无效
 *        1：成功。凭证有效
 *        2：网络错误，需要重新验证
 */
+ (void)verifyReceiptData:(NSData *)receiptData completion:(void(^)(NSInteger status))completion
{
    NSString * receiptStr = [[NSString alloc]initWithData:receiptData encoding:NSUTF8StringEncoding];
    //凭证base64编码
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:kNilOptions];

    NSMutableDictionary *mBody = @{@"receipt-data":encodeStr}.mutableCopy;
    [mBody addEntriesFromDictionary:@{@"exclude-old-transactions":@(PayAppInPurchase.excludeOldTransactions)}];
    if (PayAppInPurchase.password) {
        [mBody addEntriesFromDictionary:@{@"password":PayAppInPurchase.password}];
    }
    NSData* mData = [NSJSONSerialization dataWithJSONObject:mBody options:kNilOptions error:nil];
    NSString *sendString = [[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding];
    PayLog(@"requestBody：%@",sendString);

    NSURL *StoreURL=nil;
    if ([self isSandboxWithReceiptString:receiptStr]) {
        StoreURL= [[NSURL alloc] initWithString: @"https://sandbox.itunes.apple.com/verifyReceipt"];
    }else{
        StoreURL= [[NSURL alloc] initWithString: @"https://buy.itunes.apple.com/verifyReceipt"];
    }
    //这个二进制数据由服务器进行验证；zl
    NSData *postData = [NSData dataWithBytes:[sendString UTF8String] length:[sendString length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:StoreURL];
    [request setHTTPMethod:@"POST"];
//    [request setTimeoutInterval:50.0];//120.0---50.0zl
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
            [self.shared machVerifyCode:status];
            
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

+ (BOOL)isSandboxWithReceiptString:(NSString *)receiptStr
{
    NSString *sandbox = @"environment=Sandbox";
    if ([receiptStr.lowercaseString containsString:sandbox.lowercaseString]) {
        return YES;
    }
    return NO;
}



@end
