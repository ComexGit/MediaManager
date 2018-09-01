//
//  ViewController.m
//  MediaManager
//
//  Created by yuqian on 2018/8/15.
//  Copyright © 2018年 yuqian. All rights reserved.
//

#import "ViewController.h"
#import "VideoCamaraCapture.h"
#import "VideoConfigParam.h"
#import "VideoH264Encoder.h"

@interface ViewController () <VideoCamaraCaptureDelegate,VideoH264EncoderDelegate>

@property (weak, nonatomic) IBOutlet UIView *sourceWindow;
@property (weak, nonatomic) IBOutlet UITextView *logView;

@property (weak, nonatomic) IBOutlet UISwitch *recordSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *soundSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *codecSwitch;

@property (strong, nonatomic) VideoCamaraCapture *vcCapture;
@property (strong, nonatomic) VideoH264Encoder *videoEncoder;
@property (strong, nonatomic) AVSampleBufferDisplayLayer *sbLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sbLayer = [AVSampleBufferDisplayLayer new];
    self.sbLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.sbLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.sourceWindow.layer addSublayer:self.sbLayer];
    self.sbLayer.frame = self.sourceWindow.bounds;
    
    VideoConfigParam *param = [VideoConfigParam new];
    param.sessionPreset = AVCaptureSessionPreset640x480;
    
    self.vcCapture = [[VideoCamaraCapture alloc] initWithParam:param delegate:self];
    self.videoEncoder = [[VideoH264Encoder alloc]initWithDelegate:self];
}

- (IBAction)clickRecord:(UISwitch *)sender {

    sender.selected = !sender.selected;
    
    if (sender.isSelected) {
        [self.vcCapture startCapture];
        [self.videoEncoder setupEncodeSession:480 height:640 fps:15 frameInterval:150];
    }
    else {
        [self.vcCapture stopCapture];
        [self.videoEncoder stopEncodeSession];
    }
}

- (IBAction)clickEncodeSwitch:(UISwitch *)sender {
    
    sender.selected = !sender.selected;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - delegate
- (void)videoCamaraDidCaptureWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    if (self.sbLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [self.sbLayer flush];
    }
    
    if (self.codecSwitch.selected) {
        [self.videoEncoder encodeFrame:sampleBuffer];
    }
    else {
        [self.sbLayer enqueueSampleBuffer:sampleBuffer];
    }
}

- (void)encoder:(VideoH264Encoder *)encoder didReceiveSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    [self.sbLayer enqueueSampleBuffer:sampleBuffer];
}

- (void)encoder:(VideoH264Encoder *)encoder didReceiveSPS:(NSData*)sps andPPS:(NSData*)pps andData:(NSData*)data pts:(int64_t)ptsInMS isKeyFrame:(BOOL)isKeyFrame
{
    const char code [] = "\x00\x00\x00\x01";
    NSData *startCode = [NSData dataWithBytes:code length:4];
    
    NSMutableData *videoData = [NSMutableData data];
    
    if (sps && pps) {
        [videoData appendData:startCode];
        [videoData appendData:sps];
        [videoData appendData:startCode];
        [videoData appendData:pps];
    }
    
    [videoData appendData:startCode];
    [videoData appendData:data];
    
    //cache or transfer
}

- (void)encoder:(VideoH264Encoder *)encoder didReceiveError:(NSInteger)errorCode {
    NSLog(@"Encoder error:%ld", errorCode);
}

@end
