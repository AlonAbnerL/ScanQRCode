//
//  ViewController.m
//  ScanQRCodde
//
//  Created by KangMei_Mac on 16/8/19.
//  Copyright © 2016年 AronAbnerL. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>{
    NSTimer * timer;
    BOOL upOrdown;
    NSInteger num;
    UIImageView * imageView;
    MBProgressHUD *hud;
}
//AVCaptureDevice :该对象代表物理输入设备,包括摄像头和麦克风.开发者可通过该对象来配置底层物理设备的属性.
@property (strong,nonatomic)AVCaptureDevice * device;

//AVCaptureDeviceInput：它是AVCaptureInput的子类,使用该对象从AVCaptureDevice设备获取数据,该对象将会被添加给AVCaptureSession管理.
@property (strong,nonatomic)AVCaptureDeviceInput * input;

//AVCaptureAudioDataOutput、AVCaptureAudioPreviewOutput、AVCaptureFileOutput、AVCaptureStillImageOutput、AVCaptureVideoDataOutput：它们都是AVCaptureOutput的子类,用于接收各种数据.该对象也会被添加给AVCaptureSession管理.其中AVCaptureFileOutput依然代表输出到文件的输出端,
//AVCaptureAudioFileOutput [BL5] 、AVCaptureMovieFileOutput [BL6] ：它们都是AVCaptureFileOutput的子类，分别代表输出到音频文件、电影文件的输出端。
@property (strong,nonatomic)AVCaptureMetadataOutput * output;

//AVCaptureSession ：该对象负责把AVCaptureDevice捕捉得到的视频或声音数据输出到输出设备中.不管执行实时的还是离线的录制,开发者都必须创建AVCaptureSession对象,并为该对象添加输入设备(负责捕捉数据)和输出端(负责接收数据).
@property (strong,nonatomic)AVCaptureSession * session;

//AVCaptureVideoPreviewLayer：该对象是CALayer的子类,开发者只要创建它的实例,并为它设置AVCaptureSession,就可以非常方便地用它来实现拍摄预览.
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (strong,nonatomic)UIImageView *line;
@property (nonatomic, strong) CALayer *containerLayer;
@property (strong,nonatomic) CALayer *maskLayer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    添加二维码边角框
    imageView = UIImageView.new;
    [self.view addSubview:imageView];
    [imageView setBackgroundColor:[UIColor clearColor]];
    imageView.image = [UIImage imageNamed:@"qrcode_border"];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).with.offset(100);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.equalTo(@((NSInteger)self.view.frame.size.width*0.6));
        make.height.equalTo(@((NSInteger)self.view.frame.size.width*0.6));
    }];
    [imageView setNeedsLayout];
    [imageView layoutIfNeeded];
    imageView.layer.borderWidth = 0.5;
    imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    
//    扫描线
    upOrdown = NO;
    num =0;
    _line = UIImageView.new;
    [imageView addSubview:_line];
    [_line setFrame:CGRectMake(0, 0, CGRectGetWidth(imageView.frame), 2)];
    _line.image = [UIImage imageNamed:@"scanline.png"];

    
    if ([self isMediaTypeVideo])
    {
//        加载出扫描器之前转个菊花圈
        hud = [[MBProgressHUD alloc] initWithView:imageView];
        hud.removeFromSuperViewOnHide = YES;
        hud.dimBackground = YES;
        [imageView addSubview:hud];
        [hud showAnimated:YES whileExecutingBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupCamera];
            });
        } completionBlock:^{
        }];
    }else
    {
//        [UIAlertView showWithTitle:@"温馨提示" message:@"请您设置允许APP访问您的相机\n设置>隐私>相机" cancelButtonTitle:@"确定" otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
//            
//        }];
    }


    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_session && ![_session isRunning]) {
        [_session startRunning];
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [timer invalidate];
}

//确认应用是否有相机权限
- (BOOL)isMediaTypeVideo//相机权限
{
    [hud hide:YES];
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        return NO;
    } else
    {
        return YES;
    }
}

//扫描成功后调用
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects lastObject];
        AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)[self.preview transformedMetadataObjectForMetadataObject:metadataObject];
        [self drawLine:obj];//显示二维码边框
        
        stringValue = metadataObject.stringValue;
    }
    
    [_session stopRunning];
    [timer invalidate];
    NSLog(@"%@",stringValue);
    
}


//扫描后给二维码添加画框
- (void)drawLine:(AVMetadataMachineReadableCodeObject *)objc
{
    NSArray *array = objc.corners;
    
    // 1.创建形状图层, 用于保存绘制的矩形
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    
    // 设置线宽
    layer.lineWidth = 2;
    layer.strokeColor = [UIColor greenColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    
    // 2.创建UIBezierPath, 绘制矩形
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint point = CGPointZero;
    int index = 0;
    
    CFDictionaryRef dict = (__bridge CFDictionaryRef)(array[index++]);
    // 把点转换为不可变字典
    // 把字典转换为点，存在point里，成功返回true 其他false
    CGPointMakeWithDictionaryRepresentation(dict, &point);
    
    [path moveToPoint:point];
    
    // 2.2连接其它线段
    for (int i = 1; i<array.count; i++) {
        CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)array[i], &point);
        [path addLineToPoint:point];
    }
    // 2.3关闭路径
    [path closePath];
    
    layer.path = path.CGPath;
    // 3.将用于保存矩形的图层添加到界面上
    [self.containerLayer addSublayer:layer];
}

//扫描动画
-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(CGRectGetMinX(_line.frame), 2*num, CGRectGetWidth(_line.frame), CGRectGetHeight(_line.frame));
        if (2*num >= CGRectGetHeight(imageView.frame)-5) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(CGRectGetMinX(_line.frame), 2*num, CGRectGetWidth(_line.frame), CGRectGetHeight(_line.frame));
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}



- (void)setupCamera
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 耗时的操作
        // Device
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        // Input
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
        
        // Output
        _output = [[AVCaptureMetadataOutput alloc]init];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
//        设置扫描区域
        CGFloat x = imageView.frame.origin.x/self.view.frame.size.width;
        CGFloat y= imageView.frame.origin.y/self.view.frame.size.height;
        CGFloat w = imageView.frame.size.width/self.view.frame.size.width;
        CGFloat h = imageView.frame.size.height/self.view.frame.size.height;
        _output.rectOfInterest = CGRectMake(y, x, h, w);
        
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input])
        {
            [_session addInput:self.input];
        }
        
        if ([_session canAddOutput:self.output])
        {
            [_session addOutput:self.output];
        }
        

        // 条码类型 AVMetadataObjectTypeQRCode
        _output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            // Preview
            _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
            _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
            _preview.frame = self.view.frame;
            [self.view.layer insertSublayer:self.preview atIndex:0];
            
            _containerLayer = [[CALayer alloc] init];
            [self.view.layer addSublayer:self.containerLayer];
            self.containerLayer.frame = self.view.frame;
            
            self.maskLayer = [[CALayer alloc] init];
            self.maskLayer.frame = self.view.layer.bounds;
            self.maskLayer.delegate = self;
            [self.view.layer insertSublayer:self.maskLayer above:_preview];
            [self.maskLayer setNeedsDisplay];

            // Start
            [_session startRunning];
        });
    });
}

//添加图层，达到暗影效果
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    if (layer == self.maskLayer)
    {
        UIGraphicsBeginImageContextWithOptions(self.maskLayer.frame.size, NO, 1.0);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor);
        CGContextFillRect(ctx, self.maskLayer.frame);
        CGRect scanFrame = imageView.frame;
        CGContextClearRect(ctx, scanFrame);
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
