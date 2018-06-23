//
//  ESCRecordMP4Tool.h
//  ESCRecordMP4Demo
//
//  Created by xiang on 2018/6/23.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface ESCRecordMP4Tool : NSObject

- (void)startRecordWithFilePath:(NSString *)filePath Width:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate audioSampleRate:(NSInteger)audioSampleRate;

- (void)addAudioFrame:(CMSampleBufferRef)sampleBufferRef;

- (void)addVideoFrame:(CMSampleBufferRef)sampleBufferRef;

- (void)stopRecord;

@end
