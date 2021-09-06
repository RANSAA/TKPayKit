# TKPayKit
支付SDK，支持微信，支付宝

<br>

### 配置
* 微信 \
https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_5	\
https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html		\
https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Pay/iOS.html		

* 支付宝 \
https://opendocs.alipay.com/open/204/105695

<br>


### 方法说明：
`kNotificationNamePaySuccess`	支付成功通知	\
`kNotificationNamePayFailed`	支付失败通知	\
`kNotificationUserInfoPayType`	通知中userInfo对应的key,用于区分支付类型 	
\
\
`handleOpenURL:`需要重写在AppDelegate或SceneDelegate中的指定方法中(详情见对应代码注释)	\
`payRequest:`请求对应的支付方式 (详情见对应代码注释)


<br>