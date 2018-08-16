//
//  VideoCamaraCapture.m
//  MediaManager
//
//  Created by yuqian on 2018/8/16.
//  Copyright © 2018年 yuqian. All rights reserved.
//

#import "VideoCamaraCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoConfigParam.h"

@interface VideoCamaraCapture() {
    
    VideoConfigParam *videoParam;
    dispatch_queue_t videoQueue;
}

@property(nonatomic, strong)  AVCaptureSession *captureSession;

@end


@implementation VideoCamaraCapture

- (instancetype)initWithParam:(VideoConfigParam *)param {
    
    if (self = [super init]) {
        
        videoParam = param;
        videoQueue = dispatch_queue_create("com.mediaMgr.videoCapture", NULL);
    }
    return self;
}

- (AVCaptureSession *)captureSession {
    
    if (_captureSession) {
        
        _captureSession = [AVCaptureSession new];
        [self configCaptureSession];
    }
    return _captureSession;
}

- (void) configCaptureSession {
    
    [_captureSession setSessionPreset:videoParam.sessionPreset];
    
    //1
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //2
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    if (videoInput && [_captureSession canAddInput:videoInput]) {
       
        [_captureSession addInput:videoInput];
    }
    
    //3
    AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
    
}

- (void) startCapture {
    
    if ([self.captureSession isRunning]) {
        dispatch_async(videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

- (void) stopCapture {
    
    if ([self.captureSession isRunning]) {
        dispatch_async(videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}


@end
