//
//  NotificationService.m
//  NotificationService
//
//  Created by Mac on 2017/2/13.
//  Copyright © 2017年 TUTK. All rights reserved.
//

#import "NotificationService.h"
#import <UIKit/UIKit.h>

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

//  你需要通过重写这个方法，来重写你的通知内容，也可以在这里下载附件内容
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {

#if 1
    self.contentHandler = contentHandler;
    
    // copy发来的通知，开始做一些处理
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    
    //self.contentHandler(self.bestAttemptContent);
  
    NSLog(@"JPush下载附件,做重写!!!");

    // 重写一些东西
    self.bestAttemptContent.title = @"标题";
    self.bestAttemptContent.subtitle = @"子标题";
    self.bestAttemptContent.body = @"来自JPush";//NotificationServiceExtension!!!";
    
    // 这里添加一些点击事件，可以在收到通知的时候，添加，也可以在拦截通知的这个扩展中添加
    //self.bestAttemptContent.categoryIdentifier = @"category1";
    
    // 附件
    NSDictionary *dict =  self.bestAttemptContent.userInfo;
    NSDictionary *notiDict = dict[@"aps"];
    
    NSLog(@"dict:%@",dict);
    /**
     2017-02-14 17:14:00.812229 NotificationService[8778:2313481] JPush下载附件,做重写!!!
     2017-02-14 17:14:00.812536 NotificationService[8778:2313481] notiDict:{
     alert =     {
     body = "\U6536\U5230\U4e00\U6253\U63a8\U9001!!!";
     subtitle = 222;
     title = 111;
     };
     badge = 1;
     category = category1;
     "mutable-content" = 1;
     sound = default;
     }
     2017-02-14 17:14:00.851047 NotificationService[8778:2313483] unsupported URL
     */
    
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
#else
    
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [NotificationService]", self.bestAttemptContent.title];
    
    NSURLSession * session = [NSURLSession sharedSession];
    NSString * attachmentPath = self.bestAttemptContent.userInfo[@"my-attachment"];
    //if exist
    if (attachmentPath && [attachmentPath hasSuffix:@"png"]) {
        //download
        NSURLSessionTask * task = [session dataTaskWithURL:[NSURL URLWithString:attachmentPath] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                NSString * localPath = [NSString stringWithFormat:@"%@/myAttachment.png", NSTemporaryDirectory()];
                if ([data writeToFile:localPath atomically:YES]) {
                    UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:@"myAttachment" URL:[NSURL fileURLWithPath:localPath] options:nil error:nil];
                    self.bestAttemptContent.attachments = @[attachment];
                }
            }
            self.contentHandler(self.bestAttemptContent);
        }];
        [task resume];
    }else{
        self.contentHandler(self.bestAttemptContent);
    }

#endif
}

//  如果处理时间太长，等不及处理了，就会把收到的apns直接展示出来
- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    
    NSLog(@"JPush应急处理!!!");
    self.contentHandler(self.bestAttemptContent);
}

//下载附件通知的方法
- (void)loadAttachmentForUrlString:(NSString *)urlStr
                          withType:(NSString *)type
                  completionHandle:(void(^)(UNNotificationAttachment *attach))completionHandler{
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlStr];
    NSString *fileExt = [self fileExtensionForMediaType:type];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        NSLog(@"%@", error.localizedDescription);
                    } else {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
                        [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
                        
                        NSError *attachmentError = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                        if (attachmentError) {
                            NSLog(@"%@", attachmentError.localizedDescription);
                        }
                    }
                    completionHandler(attachment);
                }] resume];
    
}

//判断文件类型的方法
- (NSString *)fileExtensionForMediaType:(NSString *)type
{
    NSString *ext = type;
    if ([type isEqualToString:@"image"]) {
        ext = @"jpg";
    }
    if ([type isEqualToString:@"video"]) {
        ext = @"mp4";
    }
    if ([type isEqualToString:@"audio"]) {
        ext = @"mp3";
    }
    return [@"." stringByAppendingString:ext];
}
@end
