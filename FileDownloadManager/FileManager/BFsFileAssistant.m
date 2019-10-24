//
//  BFFileAssistant.m
//  BFFileManagerDemo
//
//  Created by BFsAlex on 2018/9/13.
//  Copyright © 2018年 BFAlex. All rights reserved.
//

#import "BFsFileAssistant.h"
#import <Photos/Photos.h>

typedef enum {
    
    BFFileTypeUnknown = 0,
    BFFileTypePhoto,
    BFFileTypeVideo,
    BFFileTypeDirectory,
    
} BFFileType;

@interface BFsFileAssistant()
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation BFsFileAssistant

#pragma mark - Property

- (NSFileManager *)fileManager {
    
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    
    return _fileManager;
}

#pragma mark - API

+ (instancetype)defaultAssistant {
    
    static BFsFileAssistant *assistant;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        assistant = [[BFsFileAssistant alloc] init];
    });
    
    return assistant;
}

- (BOOL)fileExists:(NSString *)fileName inDirectoryPath:(NSString *)directoryPath {
    
    // 方法一
    //    BOOL fExists = NO;
    //    NSArray *files = [self getFilesInFolder:folderName];
    //    for (NSString *file in files) {
    //        NSLog(@"文件[%@]类型为：%d", file, [self checkFileType:file]);
    //        if ([fileName isEqualToString:file]) {
    //            fExists = YES;
    //        }
    //    }
    
    // 方法二
    NSString *filePath = [self getFilePath:fileName fromDirectoryPath:directoryPath];
    BOOL fExists = [self.fileManager fileExistsAtPath:filePath];
    
    return fExists;
}

- (BOOL)isFileExists:(NSString *)filePath {
    
    if (filePath.length > 0) {
        return [self.fileManager fileExistsAtPath:filePath];
    } else {
        return NO;
    }
}

- (NSString *)getFilePath:(NSString *)fileName fromDirectoryPath:(NSString *)dirtPath {
    
    NSString *filePath = [dirtPath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

- (NSArray *)getFilesFromDirectoryPath:(NSString *)directoryPath {
    
    NSMutableArray *files = [NSMutableArray array];
    NSError *fError;
    
    NSArray *fileList = [self.fileManager contentsOfDirectoryAtPath:directoryPath error:&fError];
    for (NSString *file in fileList) {
        NSLog(@"%@子目录之一：%@", self.fileManager, file);
        if (file) {
            [files addObject:file];
        }
    }
    
    return files;
}

- (NSString *)getDirectoryPathOfFolderInDocumentsDirectory:(NSString *)folderName {
    
    return [self getDirectoryPathFromDirectories:@[folderName] isBaseOnDocuments:YES];
}

- (NSString *)getDirectoryPathFromDirectories:(NSArray *)directoryList {
    
    return [self getDirectoryPathFromDirectories:directoryList isBaseOnDocuments:YES];
}

- (NSString *)getDirectoryPathFromDirectories:(NSArray *)directoryList isBaseOnDocuments:(BOOL)isInDocumentsFolder {
    
    NSString *homeDir = NSHomeDirectory();
    if (isInDocumentsFolder) {
        homeDir = [homeDir stringByAppendingPathComponent:@"Documents"];
    }
    
    NSString *targetPath = [homeDir copy];
    for (int i = 0; i < directoryList.count; i++) {
        NSString *dirName = directoryList[i];
        targetPath = [targetPath stringByAppendingPathComponent:dirName];
    }
    
    if (![self.fileManager fileExistsAtPath:targetPath]) {
        [self.fileManager createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return targetPath;
}

- (BOOL)saveFile:(NSData *)fData toPath:(NSString *)filePath {
    
    BOOL result = [self.fileManager createFileAtPath:filePath contents:fData attributes:nil];
    
    return result;
}

- (BOOL)moveFileFromPath:(NSString *)fromPath toPath:(NSString *)toPath {
    
    return [self.fileManager moveItemAtPath:fromPath toPath:toPath error:nil];
}

- (BOOL)deleteFileAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
    
    return [self.fileManager removeItemAtPath:path error:error];
}

#pragma mark Album

- (void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName andResult:(resultBlock)resultBlock {
    
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        if (PHAuthorizationStatusDenied == status) {
            if (PHAuthorizationStatusNotDetermined != authStatus) {
                NSError *error = [self errorForDescription:@"No Authorization"];
                if (resultBlock) {
                    resultBlock(self, nil, error);
                }
            }
        } else if (PHAuthorizationStatusAuthorized == status) {
            // 保存
            [self saveImage:image toAlbum:albumName andResult:resultBlock];
        } else if (PHAuthorizationStatusRestricted) {
            NSError *error = [self errorForDescription:@"System Error"];
            if (resultBlock) {
                resultBlock(self, nil, error);
            }
        }
    }];
}

// 保存图片到自定义相册
- (void)saveImageIntoAlbum:(UIImage *)image album:(NSString *)albumName andResult:(resultBlock)resultBlock
{
    NSError *error = nil;
    
    // 获得相片
    PHFetchResult<PHAsset *> *createdAssets = [self createdAssets:image error:error];
    if (createdAssets == nil) {
        if (resultBlock) {
            error = [self errorForDescription:@"保存图片失败！"];
            resultBlock(self, nil, error);
        }
        return;
    }
    
    // 获得相册
    PHAssetCollection *createdCollection = [self createdCollection:albumName error:error];
    if (createdCollection == nil) {
        if (resultBlock) {
            error = [self errorForDescription:@"创建或者获取相册失败！"];
            resultBlock(self, nil, error);
        }
        return;
    }
    
    // 添加刚才保存的图片到【自定义相册】
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
        [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    if (resultBlock) {
        resultBlock(self, nil, error);
    }
}

// 获得相片
- (PHFetchResult<PHAsset *> *)createdAssets:(UIImage *)image error:(NSError *)error
{
    __block NSString *assetID = nil;
    
    // 保存图片到【相机胶卷】
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        assetID = [PHAssetChangeRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
    } error:&error];
    
    if (error) return nil;
    
    // 获取刚才保存的相片
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[assetID] options:nil];
}

// 获得当前App对应的自定义相册
- (PHAssetCollection *)createdCollection:(NSString *)targetAlbum error:(NSError *)error
{
    // 获得APP名字
    NSString *title;
    if (targetAlbum.length > 0) {
        title = targetAlbum;
    } else {
        title = [NSBundle mainBundle].infoDictionary[(__bridge NSString *)kCFBundleNameKey];
    }
    
    // 抓取所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    // 查找当前App对应的自定义相册
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            return collection;
        }
    }
    
    /** 当前App对应的自定义相册没有被创建过 **/
    // 创建一个【自定义相册】
    __block NSString *createdCollectionID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    if (error) return nil;
    
    // 根据唯一标识获得刚才创建的相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionID] options:nil].firstObject;
}

#pragma mark MediaFile

+ (void)saveMeidaFileIntoDeviceAlbumn:(NSString *)filePath video:(BOOL)isVideo {
    // 判断授权状态
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted) { // 此应用程序没有被授权访问的照片数据。可能是家长控制权限。
        NSLog(@"因为系统原因, 无法访问相册");
    } else if (status == PHAuthorizationStatusDenied) { // 用户拒绝访问相册
        NSLog(@"用户拒绝访问相册, 无法访问相册");
    } else if (status == PHAuthorizationStatusAuthorized) { // 用户允许访问相册
        // 放一些使用相册的代码
        [self saveMediaToPhone:filePath video:isVideo];
    } else if (status == PHAuthorizationStatusNotDetermined) { // 用户还没有做出选择
        // 弹框请求用户授权
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) { // 用户点击了好
                // 放一些使用相册的代码
                [self saveMediaToPhone:filePath video:isVideo];
            }
        }];
    }
}

+ (void)saveMediaToPhone:(NSString *)filePath video:(BOOL)isVideo {
    __block  NSString *assetLocalIdentifier;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSURL *url = [NSURL fileURLWithPath:filePath];
        if (!isVideo) {
            //1.保存图片到相机胶卷中----创建图片的请求
            assetLocalIdentifier = [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:url].placeholderForCreatedAsset.localIdentifier;
        }else {
            //1.保存视频到相机胶卷中----创建图片的请求
            assetLocalIdentifier = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:url].placeholderForCreatedAsset.localIdentifier;
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if(success == NO){
            NSLog(@"保存图片/视频失败----(创建图片/视频的请求)");
            return ;
        }
        PHAssetCollection *collection = [self getCustomCollection];
        if (!collection) return;
        // 3.将刚刚添加到"相机胶卷"中的图片到"自己创建相簿"中
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //获得图片/视频
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:nil].lastObject;
            //添加图片/视频到相簿中的请求
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            // 添加图片/视频到相簿
            [request addAssets:@[asset]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if(success){
                NSLog(@"保存图片/视频到创建的相簿成功");
            }else{
                NSLog(@"保存图片/视频到创建的相簿失败");
            }
        }];
    }];
}

/**
 获取自定义相册
 */
+ (PHAssetCollection *)getCustomCollection {
    // 获取app名字  相册以app名字命名
    NSString *appName = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    // 检查是否已经创建自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:appName]) {
            return collection;
        }
    }
    
    // 没有则创建一个
    __block NSString *createdCollectionId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:appName].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];
    if (!createdCollectionId) return nil;
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
}

#pragma mark - Feature

- (BFFileType)checkFileType:(NSString *)fileName {
    
    BFFileType fileType = BFFileTypeUnknown;
    
    // 方法一
    //    if ([fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".png"]) {
    //        fileType = BFFileTypePhoto;
    //    } else if ([fileName hasSuffix:@".mov"] || [fileName hasSuffix:@".mp4"]) {
    //        fileType = BFFileTypeVideo;
    //    }
    
    // 方法二
    if (BFFileTypeUnknown == fileType) {    // photo
        NSArray *photoTypies = @[@".jpg", @".png"];
        for (NSString *type in photoTypies) {
            if ([fileName hasSuffix:type]) {
                fileType = BFFileTypePhoto;
                break;
            }
        }
    }
    if (BFFileTypeUnknown == fileType) {    // video
        NSArray *videoTypies = @[@".mov", @".mp4"];
        for (NSString *type in videoTypies) {
            if ([fileName hasSuffix:type]) {
                fileType = BFFileTypeVideo;
                break;
            }
        }
    }
    
    return fileType;
}

- (NSError *)errorForDescription:(NSString *)description {
    
    if (description.length < 0) {
        description = @"Unknown reason";
    }
    return [NSError errorWithDomain:NSURLErrorDomain code:110 userInfo:@{NSLocalizedDescriptionKey:description}];
}

@end
