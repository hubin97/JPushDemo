//
//  AppDelegate.h
//  JPushDemo
//
//  Created by Mac on 2017/2/13.
//  Copyright © 2017年 TUTK. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 JPush SDK 相关事件监听
 
 建议开发者加上API里面提供的以下类型的通知：
 extern NSString *const kJPFNetworkIsConnectingNotification; // 正在连接中
 extern NSString * const kJPFNetworkDidSetupNotification; // 建立连接
 extern NSString * const kJPFNetworkDidCloseNotification; // 关闭连接
 extern NSString * const kJPFNetworkDidRegisterNotification; // 注册成功
 extern NSString *const kJPFNetworkFailedRegisterNotification; //注册失败
 extern NSString * const kJPFNetworkDidLoginNotification; // 登录成功
 温馨提示：
 Registration id 需要添加注册kJPFNetworkDidLoginNotification通知的方法里获取，也可以调用[registrationIDCompletionHandler:]方法，通过completionHandler获取
 extern NSString * const kJPFNetworkDidReceiveMessageNotification; // 收到自定义消息(非APNs)
 其中，kJPFNetworkDidReceiveMessageNotification传递的数据可以通过NSNotification中的userInfo方法获取，包括标题、内容、extras信息等
 */


/**
 JPush集成流程
 */

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

