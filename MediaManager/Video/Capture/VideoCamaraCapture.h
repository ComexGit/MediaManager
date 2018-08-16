//
//  VideoCamaraCapture.h
//  MediaManager
//
//  Created by yuqian on 2018/8/16.
//  Copyright © 2018年 yuqian. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoConfigParam;

@interface VideoCamaraCapture : NSObject

- (instancetype)initWithParam:(VideoConfigParam *)param;

- (void) startCapture;
- (void) stopCapture;

@end