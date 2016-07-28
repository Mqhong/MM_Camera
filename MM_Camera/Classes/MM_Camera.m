//
//  MM_Camera.m
//  使用相机和相册功能
//
//  Created by mm on 16/7/27.
//  Copyright © 2016年 mm. All rights reserved.
//

#import "MM_Camera.h"

//#import "KVNProgress.h"

#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight  [UIScreen mainScreen].bounds.size.height

@interface MM_Camera()
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic,strong) AVCaptureSession *session;

/**
 *  输入设备
 */
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;

/**
 *  照片输出流
 */
@property (nonatomic,strong) AVCaptureStillImageOutput *stillImageOutput;

/**
 *  预览图层
 */
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;


//界面控件
@property (nonatomic,strong) UIView *backView;

@property (nonatomic,strong) UISegmentedControl *switchCarmeraSegment;

@property (nonatomic,strong) UIBarButtonItem *flashButton;


//AVCaptureSession控制输入和输出设备之间的数据传递
//AVCaptureDeviceInput调用所有的输入硬件。例如摄像头和麦克风
//AVCaptureStillImageOutput用于输出图像
//AVCaptureVideoPreviewLayer镜头捕捉到得预览图层



@end

@implementation MM_Camera


-(void)viewDidLoad{
    self.view.backgroundColor = [UIColor whiteColor];
    [super viewDidLoad];
    [self initAVCaptureSession];
}

#pragma mark- 初始化所有需要的东西，初始化之后，就可以在界面上看到摄像头捕捉到的视图

-(void)initAVCaptureSession{
    
    //判断设备是否有摄像头
    if (![self isCameraAvailable]) {
//        [KVNProgress showErrorWithStatus:@"设备没有摄像头"];
        return;
    }
    
    self.backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight)];
    
    [self.view addSubview:self.backView];
    
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候，必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为关闭
    //    AVCaptureFlashModeOff  = 0,
    //    AVCaptureFlashModeOn   = 1,
    //    AVCaptureFlashModeAuto = 2
    [device setFlashMode:AVCaptureFlashModeOff];
    
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    
    if (error) {
        NSLog(@"%@",error);
    }
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。 AVVideoCodecJPEG 输出jpeg格式图片
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    NSLog(@"%f",kMainScreenWidth);
    self.previewLayer.frame = CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight);
    self.backView.layer.masksToBounds = YES;
    [self.backView.layer addSublayer:self.previewLayer];
    
    
    UIButton *takephotobtn = [UIButton buttonWithType:UIButtonTypeCustom];
    takephotobtn.frame = CGRectMake(0, self.view.bounds.size.height - 50, 80, 50);
    [takephotobtn setTitle:@"拍照" forState:UIControlStateNormal];
    takephotobtn.backgroundColor = [UIColor orangeColor];
    [takephotobtn addTarget:self action:@selector(takePhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takephotobtn];
    
    UIButton *flashbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    flashbtn.frame = CGRectMake(CGRectGetMaxX(takephotobtn.frame)+10, takephotobtn.frame.origin.y, 80, 50);
    [flashbtn setTitle:@"设置闪光灯" forState:UIControlStateNormal];
    flashbtn.backgroundColor = [UIColor orangeColor];
    [flashbtn addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashbtn];
    
    
}

#pragma mark- 在viewwillappear,viewDidDisappear方法里开启和关闭session
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}


#pragma mark- 获取设备方向的方法，再配置图片输出的时候需要使用
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        result = AVCaptureVideoOrientationLandscapeRight;
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight){
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}


#pragma mark- 拍照按钮方法
-(void)takePhotoButtonClick{
    
    
    //判断前面的摄像头是否可用
    if (![self isFrontCameraAvailable]) {
//        [KVNProgress showErrorWithStatus:@"前面摄像头无法使用"];
        NSLog(@"前面摄像头无法使用");
        return;
    }
    
    //判断是否允许访问
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized:
                NSLog(@"权限允许访问");
                [self canshowcarmer];
                break;
            case PHAuthorizationStatusRestricted:
                NSLog(@"权限不允许访问:PHAuthorizationStatusRestricted");
//                [KVNProgress showErrorWithStatus:@"这里不允许访问"];
                
                return ;
            case PHAuthorizationStatusDenied:
                NSLog(@"权限不允许访问:PHAuthorizationStatusDenied");
//                [KVNProgress showErrorWithStatus:@"这里不允许访问"];
                return ;
            default:
                break;
        }
    }];
    
    
}

#pragma mark- 判断设备是否有摄像头
-(BOOL)isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark- 前面的摄像头是否可用
-(BOOL)isFrontCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

#pragma mark- 后面的摄像头是否可用
-(BOOL)isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

#pragma mark- 允许访问之后才会调用的方法
-(void)canshowcarmer{
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:1];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:jpegData];
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
#pragma mark 这里可以设置一个蒙板,显示刚刚照的照片，然后设置修改啊什么的。
            
            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            
            dispatch_sync(dispatch_get_main_queue(),^{
                NSLog(@"存进相册了");
//                [KVNProgress showSuccessWithStatus:@"存进相册了"];
            });
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"错误:%@",error);
                dispatch_sync(dispatch_get_main_queue(),^{
//                    [KVNProgress showErrorWithStatus:@"出错了"];
                });
            }
        }];
    }];
}

#pragma mark- 闪光灯

-(void)flashButtonClick:(UIButton *)btn{
    NSLog(@"闪光灯方法");
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
//        AVCaptureFlashModeOff  = 0,关闭闪光灯
//        AVCaptureFlashModeOn   = 1,打开闪光灯
//        AVCaptureFlashModeAuto = 2,设置闪光灯为自动
        
        
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            [btn setTitle:@"flashOn" forState:UIControlStateNormal];
//            [KVNProgress showSuccessWithStatus:@"已打开闪光灯"];
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeAuto;
            [btn setTitle:@"flashAuto" forState:UIControlStateNormal];
//            [KVNProgress showSuccessWithStatus:@"闪光灯设置为自动模式"];
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
            [btn setTitle:@"flashOff" forState:UIControlStateNormal];
//            [KVNProgress showSuccessWithStatus:@"已关闭闪光灯"];
        }
    }else{
        NSLog(@"设备不支持闪光灯");
//        [KVNProgress showErrorWithStatus:@"设备不支持闪光灯"];
    }
    
    [device unlockForConfiguration];
}


-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    NSLog(@"在这里接受到了内存问题");
}









































@end
