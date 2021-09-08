//
//  AppDelegate.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/6.
//

#import "AppDelegate.h"
#import "TKPayKit.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [PayWeChat startLog];
    [PayWeChat registerApp:@"34" universalLink:@"353"];
    [PayWeChat checkEnv];


    [PayAppInPurchase registerApp];

//    NSString *str = @"";
//    NSDictionary *dic = @{@"111":@"111",@"str":str};
//    NSLog(@"dic:%@",dic);
//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
//    path = [path stringByAppendingFormat:@"/Preferences/AppInPurchase.plist"];
//    NSLog(@"path:%@",path);
//
////    path = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) lastObject];
////    path = [path stringByAppendingFormat:@"/TKPayDemo.text"];
//    NSError *err = nil;
//    [path writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
//    if (err) {
//        NSLog(@"err:%@",err);
//    }
//
//    NSUserDefaults *ser = [[NSUserDefaults alloc] initWithSuiteName:@"123"];
//    [ser setBool:YES forKey:@"Test"];
//    [ser synchronize];


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


@end
