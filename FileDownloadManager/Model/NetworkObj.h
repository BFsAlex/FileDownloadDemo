//
//  NetworkObj.h
//  FileDownloadManager
//
//  Created by 刘玲 on 2019/10/24.
//  Copyright © 2019年 BFs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkObj : NSObject

+ (instancetype)networkObj;
//
- (void)readToHearbeat;
- (void)changeToPlaybackMode:(void(^)(NSError *error, id result))resultBlock;
- (void)getFileList:(void(^)(NSError *error, id result))resultBlock;
- (void)downloadFile:(NSString *)filePath progress:(void(^)(NSString *progressTxt))progressBlock result:(void(^)(NSError *error, id result))resultBlock;

@end

NS_ASSUME_NONNULL_END
