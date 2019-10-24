//
//  FileModel.h
//  FileDownloadManager
//
//  Created by 刘玲 on 2019/10/24.
//  Copyright © 2019年 BFs. All rights reserved.
//

/*
 {
 File =                 {
 ATTR =                     {
 content = 32;
 };
 FPATH =                     {
 content = "A:\\CARDV\\Movie\\20191024143443_000178.TS";
 };
 NAME =                     {
 content = "20191024143443_000178.TS";
 };
 SIZE =                     {
 content = 121503460;
 };
 TIME =                     {
 content = "2019/10/24 14:35:42";
 };
 TIMECODE =                     {
 content = 1331197045;
 };
 };
 content = "";
 },
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileModel : NSObject
@property (nonatomic, strong) NSString *attr;
@property (nonatomic, strong) NSString *fPath;
@property (nonatomic, strong) NSString *fName;
@property (nonatomic, strong) NSString *fSize;
@property (nonatomic, strong) NSString *fTime;
@property (nonatomic, strong) NSString *fTimeCode;

//  http://192.168.1.254/CARDV/Movie/20191024143643_000180.TS
@property (nonatomic, strong) NSString *fDownloadPath;  

@end

NS_ASSUME_NONNULL_END
