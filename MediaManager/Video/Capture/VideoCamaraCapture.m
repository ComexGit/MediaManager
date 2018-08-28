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

@interface VideoCamaraCapture() <AVCaptureVideoDataOutputSampleBufferDelegate>{
    
    VideoConfigParam *videoParam;
    dispatch_queue_t videoQueue;
}

@property(nonatomic, strong)  AVCaptureSession *captureSession;
@property(nonatomic, strong)  AVCaptureVideoDataOutput *videoOutput;
@property(nonatomic, strong)  AVCaptureConnection *videoConnection;
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
    
    if (!_captureSession) {
        
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
    self.videoOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *videoOutputSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:
                                              @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
                                          }; 
    _videoOutput.videoSettings = videoOutputSettings;
    [_videoOutput setSampleBufferDelegate:self queue:videoQueue];
    [self.captureSession addOutput:_videoOutput];
    
    //4
    if (self.videoOutput) {
        
        self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        
        if (self.videoConnection) {
            self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            self.videoConnection.automaticallyAdjustsVideoMirroring = NO;
        }
    }
}

- (void) startCapture {
    
    if (![self.captureSession isRunning]) {
        dispatch_sync(videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

- (void) stopCapture {
    
    if ([self.captureSession isRunning]) {
        dispatch_sync(videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.displayLayer) {
        [self.displayLayer enqueueSampleBuffer:sampleBuffer];
    }
}


@end
