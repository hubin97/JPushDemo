#JPushDemo 
#JPush+iOS 10新特性(简易图文推送)
#前言
     如果仅仅是为了实现推送这一功能,选择可能会有很多; 但是使用三方框架肯定是非常快捷方便的.本文以极光推送的集成为例.
     若要实现简易图文推送,只需使用iOS10新特性服务扩展即可( UNNotificationServiceExtension);
     但是如果仍需定义通知栏收到推送的显示内容以及样式,则需要通知内容扩展(UNNotificationContentExtension)
    接下来三个段落主要由以上需求展开.

##一: 集成极光推送
###1.极光开发者服务控制台创建应用
          完成创建操作可获得一个AppKey,此AppKey在后续代码集成时需要用到.
          备注: 具体操作可参考:https://docs.jiguang.cn/jpush/console/Instructions/
###2.制作证书(App证书,推送证书,证书相关配置文件)
          以个人开发者账号为例. 首先,创建一个App所需的bundle id ;接着可视情况分别创建开发/发布证书;  再则申请相应的推送证书,并下载推送证书(极光推送服务控制台需要上传.p12推送证书文件); 最后根据App证书配置证书描述文件.
          备注: 证书制作可参考:https://docs.jiguang.cn/jpush/client/iOS/ios_cer_guide/
          注意: 极光推送分别支持开发和发布环境下,发收通知测试
###3.上传推送证书至极光推送服务控制台
          将第2步下载的aps证书(开发/发布),添加到钥匙串; 然后重新导出为.p12文件.接着上传推送证书生成的p12文件至极光推送服务控制台
          注意:命名最好使用全英文,避免不必要的问题
###4.代码集成,项目配置
####(1)添加Framework
```obj-c
1. CFNetwork.framework
2. CoreFoundation.framework
3. CoreTelephony.framework
4. SystemConfiguration.framework
5. CoreGraphics.framework
6. Foundation.framework
7. UIKit.framework
8. Security.framework
9. libz.tbd (Xcode7以下版本是libz.dylib)
10. AdSupport.framework (获取IDFA需要；如果不使用IDFA，请不要添加)
11. UserNotifications.framework (Xcode8及以上)
12. libresolv.tbd (JPush 2.2.0及以上版本需要, Xcode7以下版本是libresolv.dylib)
```
####(2)项目配置
    Build Settings
    如果你的工程需要支持小于7.0的iOS系统，请到Build Settings 关闭 bitCode 选项，否则将无法正常编译通过。
    Capabilities
    如使用Xcode8及以上环境开发，请开启Application Target的
    Capabilities->Push Notifications选项,并确认Steps全部勾上
    Capabilities->Background Modes选中Remote notification

####(3)AppDelegate代码段
```obj-c
// 引入JPush功能所需头文件
#import "JPUSHService.h"
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
//添加代理 <JPUSHRegisterDelegate>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    //notice: 3.0.0及以后版本注册可以这样写，也可以继续用之前的注册方式
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
    [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    // notice: 2.1.5版本的SDK新增的注册方法，改成可上报IDFA，如果没有使用IDFA直接传nil
    // 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
    // isProduction 是否生产环境. 如果为开发状态,设置为 NO; 如果为生产状态,应改为 YES.
    BOOL isProduction = YES;
#if DEBUG
    isProduction = NO;
#endif
    [JPUSHService setupWithOption:launchOptions appKey:@“e6176251f33efa2f56a54873" channel:nil apsForProduction:isProduction advertisingIdentifier:nil];
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
   // Required - 注册 DeviceToken
    [JPUSHService registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //Optional
    NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

#pragma mark- JPUSHRegisterDelegate
// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    /**
     (lldb) po userInfo
     {
     "_j_msgid" = 3172642805;
     aps =     {
        alert = 11111;
        badge = 1;
        sound = default;
        };
     }
     */
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler();  // 系统要求执行这个方法
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Required, iOS 7 Support
    [JPUSHService handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Required,For systems with less than or equal to iOS6
    [JPUSHService handleRemoteNotification:userInfo];
}
#pragma mark ---------------
```

###5.配置极光平台推送内容
          推送内容务必填充body内容(否则无法收到推送), 目标平台（必选）

##二: 新特性扩展推送图片  
###1. 在项目Target添加Notification Service Extension项; 命名为 NotificationService,
接着会自动生成NotificationService项目文件夹

     UNNotificationServiceExtension 主要包含两个方法
     ```obj-c
     // You are expected to override this method to implement push notification modification.
     //补充: 你需要通过重写这个方法，来重写你的通知内容，也可以在这里下载附件内容
     - (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler;

     // Will be called just before this extension is terminated by the system. You may choose whether to override this method.
     //补充: 如果处理时间太长，等不及处理了，就会把收到的apns直接展示出来
     - (void)serviceExtensionTimeWillExpire;
     ```
###2.项目配置注意:
    App与Extension target编译时需统一编译模式,同时debug,或者同时release
    DEBUG模式, Extension code和App General全选Automatically manage signing ;  BuildSettings 全选iOS Developer,  Automatic
    RELEASE模式,Extension和App 全部选定release并统一证书,根据不同Bundle Identifier配置不同配置文件
###3.code部分
   didReceiveNotificationRequest方法做修改
   ```obj-c
    NSDictionary *dict =  self.bestAttemptContent.userInfo;
    NSString *imgUrl = [NSString stringWithFormat:@"%@",dict[@"imageAbsoluteString"]];
    if (!imgUrl.length) {
        self.contentHandler(self.bestAttemptContent);
    }
    [self loadAttachmentForUrlString:imgUrl withType:@"png" completionHandle:^(UNNotificationAttachment *attach) {
        if (attach) {
            self.bestAttemptContent.attachments = [NSArray arrayWithObject:attach];
        }
        self.contentHandler(self.bestAttemptContent);
    }];
    ```
###4.JPush控制台配置 

      
##三: 自定义推送内容与格式 (不是很稳定,待续)
##四: 回顾总结





======
##备注
JPush推送推送字串格式:

======
