//
//  VideoH264Encoder.h
//  MediaManager
//
//  Created by yuqian on 2018/8/28.
//  Copyright © 2018年 yuqian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@class VideoH264Encoder;

@protocol VideoH264EncoderDelegate <NSObject>

- (void)encoder:(VideoH264Encoder *)encoder didReceiveSPS:(NSData*)sps andPPS:(NSData*)pps andData:(NSData*)data pts:(int64_t)ptsInMS isKeyFrame:(BOOL)isKeyFrame;
- (void)encoder:(VideoH264Encoder *)encoder didReceiveSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)encoder:(VideoH264Encoder *)encoder didReceiveError:(NSInteger)errorCode;
@end

@interface VideoH264Encoder : NSObject

- (instancetype)initWithDelegate:(id<VideoH264EncoderDelegate>)delegate;
- (void) setupEncodeSession:(int32_t)width height:(int32_t)height fps:(int32_t)fps frameInterval:(int32_t)frameInterval;
- (void) encodeFrame:(CMSampleBufferRef)sampleBuffer;
- (void) stopEncodeSession;

@end
