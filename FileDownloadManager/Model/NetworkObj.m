//
//  NetworkObj.m
//  FileDownloadManager
//
//  Created by 刘玲 on 2019/10/24.
//  Copyright © 2019年 BFs. All rights reserved.
//

#import "NetworkObj.h"
#import <AFNetworking.h>
#import "XMLParser.h"


@interface NetworkObj () <NSXMLParserDelegate> {
    AFHTTPSessionManager *_operation;
    dispatch_queue_t _heartbeatQueue;
}
@property (nonatomic, assign) BOOL heartbeatRuning;
//@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) XMLParser *xmlParser;

@end

@implementation NetworkObj

- (XMLParser *)xmlParser {
    
    if (!_xmlParser) {
        _xmlParser = [[XMLParser alloc] init];
    }
    return _xmlParser;
}

+ (instancetype)networkObj {
    
    return [[NetworkObj alloc] init];
}

- (instancetype)init {
    
    if (self = [super init]) {
        _heartbeatQueue = dispatch_queue_create("com.heartbeat", NULL);
        _videos = [NSMutableArray array];
    }
    return self;
}

#pragma mark - API

- (void)readToHearbeat {
    [self startHeartbeat];
}

- (void)changeToPlaybackMode:(void (^)(NSError * _Nonnull, id _Nonnull))resultBlock {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:@"http://192.168.1.254/?custom=1&cmd=3001&par=2"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        if (resultBlock) {
            resultBlock(error, response);
        }
    }];
    [dataTask resume];
}

- (void)getFileList:(void(^)(NSError *error, id result))resultBlock {
    
    //
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.254/?custom=1&cmd=3015"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData *xmlData = [NSData dataWithContentsOfURL:url];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self.xmlParser parseData:xmlData success:^(id parsedData) {
        if (resultBlock) {
            resultBlock(nil, parsedData);
        }
    } failure:^(NSError *error) {
        if (resultBlock) {
            resultBlock(error, nil);
        }
    }];
    
}

- (void)downloadFile:(NSString *)filePath progress:(nonnull void (^)(NSString * _Nonnull))progressBlock result:(nonnull void (^)(NSError * _Nonnull, id _Nonnull))resultBlock {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:filePath];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"下载进度：%.0f％", downloadProgress.fractionCompleted * 100);
        if (progressBlock) {
            progressBlock([NSString stringWithFormat:@"%.0f％", downloadProgress.fractionCompleted * 100]);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *localPath = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        return localPath;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (resultBlock) {
            resultBlock(error, filePath);
        }
    }];
    [downloadTask resume];
}

#pragma mark - Heartbeat

- (void)deviceHeartbeat {
    NSLog(@"[%@ %@]", [self class], NSStringFromSelector(_cmd));
    dispatch_async(_heartbeatQueue, ^{
        while (self->_heartbeatRuning) {
            //
            NSURLSessionTask *task = [[NSURLSession sharedSession]dataTaskWithURL:[NSURL URLWithString:@"http://192.168.1.254/?custom=1&cmd=3016"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"心跳异常:%@", error.localizedDescription);
                } else {
                    NSLog(@"心跳正常");
                }
            }];
            [task resume];
            
            [NSThread sleepForTimeInterval:5.f];
        }
    });
}

- (void)startHeartbeat {
    if (_heartbeatRuning) return;
    _heartbeatRuning = YES;
    
    //
    [self deviceHeartbeat];
}

#pragma mark - Download



@end
