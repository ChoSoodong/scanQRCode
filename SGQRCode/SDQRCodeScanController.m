//
//  SDQRCodeScanController.m
//  AlphaPay
//
//  Created by xialan on 2019/2/18.
//  Copyright © 2019 HARAM. All rights reserved.
//

#import "SDQRCodeScanController.h"
#import "SGQRCode.h"
#import "MBProgressHUD+SGQRCode.h"

@interface SDQRCodeScanController (){
    SGQRCodeObtain *obtain;
}
@property (nonatomic, strong) SGQRCodeScanView *scanView;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, assign) BOOL stop;


@end

@implementation SDQRCodeScanController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_stop) {
        [obtain startRunningWithBefore:nil completion:nil];
    }
    [self.view bringSubviewToFront:self.naviView];
    
    

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.scanView addTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scanView removeTimer];
    
}

- (void)dealloc {
    NSLog(@" - dealloc");
    [self removeScanningView];
}




- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    obtain = [SGQRCodeObtain QRCodeObtain];
    
    //检查相机权限
    [self checkAuthorization];
    
}

#pragma mark - 初始化
-(void)setupUI{
    [self setupQRCodeScan];
    [self setupNavigationBar];
    [self.view addSubview:self.scanView];
    [self.view addSubview:self.promptLabel];
}


#pragma mark - 检查权限
- (void)checkAuthorization{
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (status) {
            case AVAuthorizationStatusNotDetermined: {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        dispatch_sync(dispatch_get_main_queue(), ^{

                            //可以扫描
                            [self setupUI];
                            
                        });
                        NSLog(@"用户第一次同意了访问相机权限 - - %@", [NSThread currentThread]);
                    } else {
                        
                        [self.navigationController popViewControllerAnimated:YES];
                        
                        NSLog(@"用户第一次拒绝了访问相机权限 - - %@", [NSThread currentThread]);
                    }
                }];
                break;
            }
            case AVAuthorizationStatusAuthorized: {
                //可以扫描
                [self setupUI];
                
                break;
            }
            case AVAuthorizationStatusDenied: {
                //前往设置打开相机权限
                UIAlertController *alertC = [UIAlertController
                                             alertControllerWithTitle:@"提示" message:@"Go to Settings\nto open Camera permissions." preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                
                [alertC addAction:alertA];
                [self presentViewController:alertC animated:YES completion:nil];
                break;
            }
            case AVAuthorizationStatusRestricted: {
                NSLog(@"因为系统原因, 无法访问相册");
                [self.navigationController popViewControllerAnimated:YES];
                
                break;
            }
                
            default:
                break;
        }
        return;
    }
    //温馨提示  //未检测到摄像头
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"Prompt" message:@"Camera not detected." preferredStyle:(UIAlertControllerStyleAlert)];
    //确认
    UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    [alertC addAction:alertA];
    [self presentViewController:alertC animated:YES completion:nil];
}




- (void)setupQRCodeScan {
    __weak typeof(self) weakSelf = self;
    
    SGQRCodeObtainConfigure *configure = [SGQRCodeObtainConfigure QRCodeObtainConfigure];
    configure.openLog = YES;
    configure.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    // 这里只是提供了几种作为参考（共：13）；需什么类型添加什么类型即可
    NSArray *arr = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    configure.metadataObjectTypes = arr;
    
    [obtain establishQRCodeObtainScanWithController:self configure:configure];
    [obtain startRunningWithBefore:^{
        //正在加载中
        [MBProgressHUD SG_showMBProgressHUDWithModifyStyleMessage:@"loading..." toView:weakSelf.view];
    } completion:^{
        [MBProgressHUD SG_hideHUDForView:weakSelf.view];
    }];
    [obtain setBlockWithQRCodeObtainScanResult:^(SGQRCodeObtain *obtain, NSString *result) {
        if (result) {
            [obtain stopRunning];
            weakSelf.stop = YES;
            [obtain playSoundName:@"SGQRCode.bundle/sound.caf"];
            
            if ([result hasPrefix:@"http"]) {
                
                NSLog(@"扫描结果--是网址%@",result);
                [[UIApplication sharedApplication].keyWindow makeToast:result duration:2 position:CSToastPositionCenter];
                
                if ([weakSelf.delegate respondsToSelector:@selector(QRCodeScanController:httpResult:)]) {
                    [weakSelf.delegate QRCodeScanController:weakSelf httpResult:result];
                }
                
                
            }else{
                
                NSLog(@"扫描结果--------不是网址");

                
                if ([weakSelf.delegate respondsToSelector:@selector(QRCodeScanController:stringResult:)]) {
                    [weakSelf.delegate QRCodeScanController:weakSelf stringResult:result];
                }
                
                
                
            }
            
            //扫描完成,退出控制器
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
            
        }
    }];
}

#pragma mark - 设置导航栏
- (void)setupNavigationBar {
    
    self.naviRightButtonHide = YES;
     //扫描二维码
    [self addBackButtonAndMiddleTitle:@"Scan QRcode" addBackBtn:YES];
    

    
    UIButton *rightBtn = [[UIButton alloc] init];
    //相册
    [rightBtn setTitle:@"Album" forState:UIControlStateNormal];
    [rightBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightBarButtonItenAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.naviView.rightBarButtonItem = rightBtn;
    
}
#pragma mark - 从相册扫描
- (void)rightBarButtonItenAction {
    __weak typeof(self) weakSelf = self;
    
    [obtain establishAuthorizationQRCodeObtainAlbumWithController:nil];
    if (obtain.isPHAuthorization == YES) {
        [self.scanView removeTimer];
    }
    [obtain setBlockWithQRCodeObtainAlbumDidCancelImagePickerController:^(SGQRCodeObtain *obtain) {
        [weakSelf.view addSubview:weakSelf.scanView];
    }];
    [obtain setBlockWithQRCodeObtainAlbumResult:^(SGQRCodeObtain *obtain, NSString *result) {
        if (result == nil) {
            NSLog(@"暂未识别出二维码");
        } else {
            if ([result hasPrefix:@"http"]) {

                NSLog(@"相册扫描结果--是网址");
                
                if ([weakSelf.delegate respondsToSelector:@selector(QRCodeScanController:httpResult:)]) {
                    [weakSelf.delegate QRCodeScanController:weakSelf httpResult:result];
                }
                
            } else {
                if ([weakSelf.delegate respondsToSelector:@selector(QRCodeScanController:stringResult:)]) {
                    [weakSelf.delegate QRCodeScanController:weakSelf stringResult:result];
                }
                
                NSLog(@"相册扫描结果------不是网址");
            }
            
            //扫描完成,退出控制器
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
            
        }
    }];
}

- (SGQRCodeScanView *)scanView {
    if (!_scanView) {
        _scanView = [[SGQRCodeScanView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SCREEN_HEIGHT)];
        // 静态库加载 bundle 里面的资源使用 SGQRCode.bundle/QRCodeScanLineGrid
        // 动态库加载直接使用 QRCodeScanLineGrid
        _scanView.scanImageName = @"scanLine";
        _scanView.scanAnimationStyle = ScanAnimationStyleDefault;
        _scanView.cornerLocation = CornerLoactionNoCorner;
        _scanView.borderColor = [UIColor colorWithHex:0x00C1DE];
        _scanView.borderLineWidth = 2;
        
    }
    return _scanView;
}
- (void)removeScanningView {
    [self.scanView removeTimer];
    [self.scanView removeFromSuperview];
    self.scanView = nil;
}

- (UILabel *)promptLabel {
    if (!_promptLabel) {
        _promptLabel = [[UILabel alloc] init];
        _promptLabel.backgroundColor = [UIColor clearColor];
        CGFloat promptLabelX = 0;
        CGFloat promptLabelY = 0.73 * self.view.frame.size.height;
        CGFloat promptLabelW = self.view.frame.size.width;
        CGFloat promptLabelH = 25;
        _promptLabel.frame = CGRectMake(promptLabelX, promptLabelY, promptLabelW, promptLabelH);
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _promptLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        //请将二维码放入框内
        _promptLabel.text = @"Please put the QRcode in the box.";
    }
    return _promptLabel;
}





@end
