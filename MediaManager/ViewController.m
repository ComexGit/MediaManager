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
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *sourceWindow;
@property (weak, nonatomic) IBOutlet UIView *desWindow;
@property (weak, nonatomic) IBOutlet UITextView *logView;

@property (weak, nonatomic) IBOutlet UISwitch *recordSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *soundSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *codecSwitch;

@property (strong, nonatomic) VideoCamaraCapture *vcCapture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVSampleBufferDisplayLayer *sbLayer = [AVSampleBufferDisplayLayer new];
    sbLayer.backgroundColor = [UIColor blackColor].CGColor;
    sbLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.sourceWindow.layer addSublayer:sbLayer];
    sbLayer.frame = self.sourceWindow.bounds;
    
    VideoConfigParam *param = [VideoConfigParam new];
    param.sessionPreset = AVCaptureSessionPreset640x480;
    
    self.vcCapture = [[VideoCamaraCapture alloc]initWithParam:param];
    self.vcCapture.displayLayer = sbLayer;
}

- (IBAction)clickRecord:(UISwitch *)sender {

    sender.selected = !sender.selected;
    
    if (sender.isSelected) {
        [self.vcCapture startCapture];
    }
    else {
        [self.vcCapture stopCapture];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
