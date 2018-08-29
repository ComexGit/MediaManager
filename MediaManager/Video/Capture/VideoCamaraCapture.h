//
//  VideoCamaraCapture.h
//  MediaManager
//
//  Created by yuqian on 2018/8/16.
//  Copyright © 2018年 yuqian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VideoConfigParam;

@protocol VideoCamaraCaptureDelegate <NSObject>

- (void) videoCamaraDidCaptureWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end


@interface VideoCamaraCapture : NSObject

- (instancetype)initWithParam:(VideoConfigParam *)param delegate:(id<VideoCamaraCaptureDelegate>)delegate;

- (void) startCapture;
- (void) stopCapture;

@end
