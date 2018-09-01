//
//  VideoH264Encoder.m
//  MediaManager
//
//  Created by yuqian on 2018/8/28.
//  Copyright © 2018年 yuqian. All rights reserved.
//

#import "VideoH264Encoder.h"


@interface VideoH264Encoder () {
    
    int frameCount;
    dispatch_queue_t encodeQueue;
    VTCompressionSessionRef encodeSession;
}

@property (nonatomic, weak) id<VideoH264EncoderDelegate> delegate;

@end

@implementation VideoH264Encoder

- (instancetype)initWithDelegate:(id<VideoH264EncoderDelegate>)delegate;{
    
    if (self = [super init]) {
        self.delegate = delegate;
        encodeQueue = dispatch_queue_create("com.mediaMgr.videoEncode", NULL);
    }
    return self;
}

- (void) setupEncodeSession:(int32_t)width height:(int32_t)height fps:(int32_t)fps frameInterval:(int32_t)frameInterval {
    
    frameCount = 0;
    
    OSStatus status =  VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, encodeOutputCallback, (__bridge void *)(self), &encodeSession);
    if (status != noErr) {
        NSLog(@"H264: Unable to create a H264 session");
        return;
    }
    
    // 设置实时编码输出（避免延迟）
    VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
    VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    
    // 设置关键帧间隔，即gop size
    CFNumberRef frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
    VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
    
    //设置期望帧率
    CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    //设置码率，均值，单位是byte
    int bitRate = width * height * 3 * 4 * 8;
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    
    //设置码率，上限，单位是bps
    int bitRateLimit = width * height * 3 * 4;
    CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
    VTSessionSetProperty(encodeSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
    
    //开始编码
    VTCompressionSessionPrepareToEncodeFrames(encodeSession);
}

//编码一帧图像
- (void) encodeFrame:(CMSampleBufferRef)sampleBuffer {
    
    dispatch_sync(encodeQueue, ^{
        
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        CMTime duration = CMSampleBufferGetOutputDuration(sampleBuffer);
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        VTEncodeInfoFlags flags;
        OSStatus statusCode = VTCompressionSessionEncodeFrame(self->encodeSession,
                                                              imageBuffer,
                                                              presentationTimeStamp,
                                                              duration,
                                                              NULL, NULL, &flags);
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        if (statusCode != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            
            [self stopEncodeSession];
            return;
        }
        NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
    });
}

- (void) stopEncodeSession
{
    VTCompressionSessionCompleteFrames(encodeSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(encodeSession);
    CFRelease(encodeSession);
    encodeSession = NULL;
}

// 编码回调，每当系统编码完一帧之后，会异步掉用该方法，此为c语言方法
void encodeOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer ) {
    
    if (status != noErr) {
        NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    VideoH264Encoder* encoder = (__bridge VideoH264Encoder*)userData;
    
    if ([encoder.delegate respondsToSelector:@selector(encoder:didReceiveSampleBuffer:)]) {
        [encoder.delegate encoder:encoder didReceiveSampleBuffer:sampleBuffer];
    }
}

- (void) sampleBufferToData:(VideoH264Encoder*) encoder sampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    NSData *sps = nil;
    NSData *pps = nil;
    NSData *data = nil;
    
    //    NSLog(@"----sample Num :%d",CMSampleBufferGetNumSamples(sampleBuffer));
    
    OSStatus ret = 0;
    if (ret == noErr) {
        
        bool keyframe = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
        
        int NALUnitHeaderLength = 0;
        if (keyframe)
        {
            CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
            // CFDictionaryRef extensionDict = CMFormatDescriptionGetExtensions(format);
            // Get the extensions
            // From the extensions get the dictionary with key "SampleDescriptionExtensionAtoms"
            // From the dict, get the value for the key "avcC"
            
            size_t sparameterSetSize=0, sparameterSetCount=0,pparameterSetSize=0,pparameterSetCount=0;
            const uint8_t *sparameterSet = NULL;
            const uint8_t *pparameterSet = NULL;
            
            ret = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, &NALUnitHeaderLength);
            
            if (ret == noErr)
            {
                ret = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, &NALUnitHeaderLength);
            }
            
            if (ret == noErr)
            {
                sps = [NSData dataWithBytesNoCopy:(void *)sparameterSet length:sparameterSetSize freeWhenDone:NO];
                pps = [NSData dataWithBytesNoCopy:(void *)pparameterSet length:pparameterSetSize freeWhenDone:NO];
            }
        }
        
        if (ret == noErr) {
            
            CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
            size_t length, totalLength;
            char *dataPointer;
            
            ret = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
            
            if (ret == noErr) {
                
                size_t bufferOffset = 0;
                
                while (bufferOffset < totalLength - NALUnitHeaderLength) {
                    
                    //读取NALU长度
                    uint32_t NALUnitLength = 0;
                    memcpy(&NALUnitLength, dataPointer + bufferOffset, NALUnitHeaderLength);
                    
                    //将长度由大端转换为小端
                    NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
                    
                    uint8_t header = *(dataPointer + bufferOffset + NALUnitHeaderLength);
                    uint8_t nalType = header & 0x1F;
                    
                    static int64_t count = 0;
                    
                    if (nalType == 0x06) {
                        if (count++%10 == 0) {
                            NSLog(@"H.264 Nal type is SEI");
                        }
                    }else {
                        //拷贝NALU数据
                        data = [NSData dataWithBytesNoCopy:(void *)(dataPointer + bufferOffset + NALUnitHeaderLength) length:NALUnitLength freeWhenDone:NO];
                        
                        if ([encoder.delegate respondsToSelector:@selector(encoder:didReceiveSPS:andPPS:andData:pts:isKeyFrame:)]) {
                            
                            if (count++%100 == 0) {
                                NSLog(@"H.264 Delegate Data:%lu, SPS&PPS:%@, isKeyFrame:%@", (unsigned long)data.length, sps&&pps?@"YES":@"NO", keyframe?@"YES":@"NO");
                            }
                            
                            CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                            NSTimeInterval pts = CMTimeGetSeconds(presentationTimeStamp);
                            
                            [encoder.delegate encoder:encoder didReceiveSPS:sps andPPS:pps andData:data pts:(int64_t)(pts*1000) isKeyFrame:keyframe];
                        }
                    }
                    
                    // 移动到blockbuffer中的下一个NALU
                    bufferOffset += NALUnitHeaderLength + NALUnitLength;
                }
            }
        }
    }
}

@end
