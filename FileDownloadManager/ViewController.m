//
//  ViewController.m
//  FileDownloadManager
//
//  Created by 刘玲 on 2019/10/24.
//  Copyright © 2019年 BFs. All rights reserved.
//

#import "ViewController.h"
#import "NetworkObj.h"
#import "FileModel.h"
#import "BFsFileAssistant.h"

@interface ViewController () {
    int _downloadIndex;
}
@property (weak, nonatomic) IBOutlet UIButton *loadFileInfoBtn;
@property (weak, nonatomic) IBOutlet UIButton *oneFile;
@property (weak, nonatomic) IBOutlet UILabel *downloadFileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *propressLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *downloadInfoConstraint;
@property (weak, nonatomic) IBOutlet UIButton *formatBtn;
@property (weak, nonatomic) IBOutlet UILabel *fileNumLabel;

@property (nonatomic, strong) NetworkObj *networkObj;
@property (nonatomic, strong) __block NSArray   *files;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.downloadInfoConstraint.constant = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.networkObj = [NetworkObj networkObj];
    [self.networkObj readToHearbeat];
}

#pragma mark - Action

- (IBAction)actionDownloadBtn:(UIButton *)sender {
    
    if (!_networkObj) {
        return;
    }
    _downloadIndex = 0;
    //
    [self.networkObj changeToPlaybackMode:^(NSError * _Nonnull error, id  _Nonnull result) {
        [self.networkObj getFileList:^(NSError * _Nonnull error, id  _Nonnull result) {
            if (error) {
                NSLog(@"get file error:%@", error.localizedDescription);
            } else {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    self.files = [self fileModelFromDict:result];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.fileNumLabel.text = [NSString stringWithFormat:@"0/%ld", self.files.count];
                        self.loadFileInfoBtn.enabled = NO;
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlert:@"没有文件数据"];
                    });
                }
            }
        }];
    }];
}

- (IBAction)actionDownloadOneFile:(UIButton *)sender {
    
    if (_downloadIndex >= self.files.count) {
//        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:@"没有文件可下载" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//            //
//        }];
//
//        [alertVC addAction:okAction];
//        [self.navigationController presentViewController:alertVC animated:YES completion:^{
//            //
//        }];
        [self showAlert:@"没有文件可下载"];
    }
    
    [self startDownloadFile:self.files[_downloadIndex]];
    _downloadIndex++;
}
- (IBAction)actionFormatBtn:(UIButton *)sender {
}

#pragma mark -

- (void)startDownloadFile:(FileModel *)fileModel {
    //
    self.fileNumLabel.text = [NSString stringWithFormat:@"%d/%ld", self->_downloadIndex, self.files.count];
    //
    self.downloadInfoConstraint.constant = 70.f;
    self.downloadFileNameLabel.text = fileModel.fName;
    
    NSString *urlStr = fileModel.fDownloadPath;
    if (urlStr.length > 0) {
        //
        NSString *flocalPath = [self fileLocalPath:fileModel.fName];
        NSLog(@"flocal path:%@", flocalPath);
        if ([[BFsFileAssistant defaultAssistant] isFileExists:flocalPath]) {
            [[BFsFileAssistant defaultAssistant] deleteFileAtPath:urlStr error:nil];
        }
        NSLog(@"file size:%@", [self formatTimeShow:fileModel.fSize]);
        //
        [self.networkObj downloadFile:urlStr progress:^(NSString * _Nonnull progressTxt) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.propressLabel.text = progressTxt;
            });
        } result:^(NSError * _Nonnull error, id  _Nonnull result) {
            if (error) {
                NSLog(@"download error:%@", error.localizedDescription);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showAlert:error.localizedDescription];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showAlert:@"下载成功"];
                });
            }
            self.downloadInfoConstraint.constant = 0;
        }];
    }
}

#pragma mark -

- (NSArray *)fileModelFromDict:(NSDictionary *)filesDict {
    
    NSMutableArray *resultFiles = [NSMutableArray array];
    NSArray *fileArr = [(NSDictionary *)[filesDict objectForKey:@"LIST"] objectForKey:@"ALLFilesArray"];
    for (NSDictionary *fileItem in fileArr) {
        //
        FileModel *model = [[FileModel alloc] init];
        //
        NSDictionary *fileDict = [fileItem objectForKey:@"File"];
        model.attr = fileDict[@"ATTR"][@"content"];
        model.fPath = fileDict[@"FPATH"][@"content"];
        model.fDownloadPath = [self fileDownloadPath:[model.fPath copy]];
        model.fName = fileDict[@"NAME"][@"content"];
        model.fSize = fileDict[@"SIZE"][@"content"];
        model.fTime = fileDict[@"TIME"][@"content"];
        model.fTimeCode = fileDict[@"TIMECODE"][@"content"];
        
        [resultFiles addObject:model];
    }
    
    return resultFiles;
}

- (NSString *)fileDownloadPath:(NSString *)fPath {
    
    if (fPath.length < 1) {
        
        return @"";
    }
   
    NSString *path = [fPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    return  [NSString stringWithFormat:@"http://192.168.1.254%@",[path substringFromIndex:2]];
}

- (NSString *)formatTimeShow:(NSString *)timeStr {
    
    if (timeStr.length > 0) {
        NSInteger num=[timeStr integerValue];
        if (num<1024) {
            return [NSString stringWithFormat:@"%ldB",(long)num];
        }else if(num<1024*1024){
            return [NSString stringWithFormat:@"%.2lfKB",num/1024.0];
        }else{
            return [NSString stringWithFormat:@"%.2lfMB",num/(1024.0*1024.0)];
        }
    }
    return @"";
}

- (NSString *)fileLocalPath:(NSString *)fileName {
    
    NSURL *documentPath = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *filePath = [documentPath URLByAppendingPathComponent:fileName];
    
    return [filePath absoluteString];
}

- (void)showAlert:(NSString *)msg {
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //
        }];
    
        [alertVC addAction:okAction];
        [self.navigationController presentViewController:alertVC animated:YES completion:^{
            //
        }];
//    });
}
@end
