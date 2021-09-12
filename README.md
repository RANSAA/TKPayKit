# TKPayKit
支付SDK，支持微信，支付宝, App In Purchase，Apple Pay
<br>

### 进度：
* **支付宝**： 已完成
* **微信支付**：已完成
* **App In Purchase**：	已完成(未测试)
* **Apple Pay**：	未完成

### 参考文档
* 微信 \
https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_5	\
https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html		\
https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Pay/iOS.html		

* 支付宝 \
https://opendocs.alipay.com/open/204/105695

* App In Purchase\
	https://blog.51cto.com/yarin/549141		\
	https://www.jianshu.com/p/f7bff61e0b31		\
	https://blog.csdn.net/u013654125/article/details/99832989		\
	https://blog.csdn.net/qcx321/article/details/80847051		\
	https://www.jianshu.com/p/de030cd6e4a3		\
	
	非消耗品的购买与恢复:\
	https://blog.csdn.net/shenjie12345678/article/details/53023804		\
	
	Receipt Validation Programming Guide:   https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/validating_receipts_with_the_app_store#//apple_ref/doc/uid/TP40010573-CH104-SW1		\
	Choose a Validation Technique:	https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/choosing_a_receipt_validation_technique#//apple_ref/doc/uid/TP40010573		\
	verifyReceipt: https://developer.apple.com/documentation/appstorereceipts/verifyreceipt		\
	requestBody:   https://developer.apple.com/documentation/appstorereceipts/requestbody		\
	responseBody:  https://developer.apple.com/documentation/appstorereceipts/responsebody		\
	expiration_intent: https://developer.apple.com/documentation/appstorereceipts/expiration_intent		\

<br>

### 公共数据：

通知相关,**支付成功/失败需要通过监听通知获取：**
```
kNotificationNamePaySuccess			支付成功通知
kNotificationNamePayFailed			支付失败通知

kNotificationUserInfoPayType		通知userinfo.key，支付类型,区分使用的那种支付方式
kNotificationUserInfoResultDic		通知userinfo.key，支付结果(可为空)，类型：NSDictionary
```


支付类型：
```
/**支付类型 */
typedef NS_ENUM(NSInteger, PayType){
	PayTypeWeChat = 0,      //微信
	PayTypeAliPay,           //支付宝
	PayTypeApplePay,        //Aappl Pay
	PayTypeAppInPurchase,       //App In Purchase 内购
};
```

使用流程：直接查看对应代码中的注释即可。
```
支付流程一般需要：
1. registerApp: 注册相关支付模块
2. handleOpenURL 需要重写在AppDelegate或SceneDelegate中的指定方法中(详情见对应代码注释)，如果需要。
3. payRequest：	 发起支付请求
4. verify验证支付结果，如果需要
	

```



<br>

### App In Purchase使用说明：
```
/**
 使用说明：
 1：在didFinishLaunchingWithOptions中注册
 2：注册之后执行checkRecordReceiptDataWithCompletion：方法检测是否有缓存的数据凭证，如果有可从list.dic中循环获取receiptDic数据
 3：如果有则需要验证收据凭证是否有效，验证分两种方式；
	1.直接在APP中验证，调用verifyReceiptData：completion：方法即可
	2.在自己的服务器中验证，需要将receiptData进行base64编码，发给服务器验证
 4：验证完毕之后需要删除缓存记录使用：removeRecordReceiptDataWithKey
 5：在需要支付的地方调用：payPequestProducts:req:type:completion:或者payRequestRestoresWithApplicationUsername：方法
 6：接收支付成功/失败通知
 7：处理支付成功通知，即需要验证收据凭证数据
	1.收据凭证数据来源与通知传递,直接通过notif.userinfo.kNotificationUserInfoResultData获取receiptDic数据
	2.从checkRecordReceiptDataWithCompletion:中list.dic中获取receiptDic数据
 8：重复执行3，4条进行收据数据验证操作

 PS:注意目前该工具还未经过测试，恢复购买（payRequestRestoresWithApplicationUsername：）方式可能不完全，后期可以根据实际需求优化。
 PS:支付成功/失败需要通过监听通知消息获取，通知支付成功之后还需要验证凭据。

 */
```












