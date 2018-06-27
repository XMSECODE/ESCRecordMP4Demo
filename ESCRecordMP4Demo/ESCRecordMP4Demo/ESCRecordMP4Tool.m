//
//  ESCRecordMP4Tool.m
//  ESCRecordMP4Demo
//
//  Created by xiang on 2018/6/23.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ESCRecordMP4Tool.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
@interface ESCRecordMP4Tool ()

@property(nonatomic,copy)NSString* filePath;

@property(nonatomic,strong)AVAssetWriter* asseetWriter;

@property(nonatomic,strong)AVAssetWriterInput* videoAssetWriterInput;

@property(nonatomic,strong)AVAssetWriterInput* audioAssetWriterInput;

@end

@implementation ESCRecordMP4Tool

- (void)startRecordWithFilePath:(NSString *)filePath Width:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate audioSampleRate:(NSInteger)audioSampleRate{
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSError *error;
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        NSLog(@"%@",error);
        return;
    }
    self.asseetWriter = writer;
    
    //写入视频大小
    NSInteger numPixels = width * height;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(frameRate),
                                             AVVideoMaxKeyFrameIntervalKey : @(frameRate),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    NSDictionary *setting = @{ AVVideoCodecKey : AVVideoCodecH264,
                               AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                               AVVideoWidthKey : @(width),
                               AVVideoHeightKey : @(height),
                               AVVideoCompressionPropertiesKey : compressionProperties };
    
    
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:setting];
    
    // 音频设置
    NSDictionary *aduioSetting = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                   AVNumberOfChannelsKey : @(1),
                                   AVSampleRateKey : @(audioSampleRate)
                                   };
    AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:aduioSetting];
    
    if ([self.asseetWriter canAddInput:videoInput]) {
        [self.asseetWriter addInput:videoInput];
        self.videoAssetWriterInput = videoInput;
        //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
        self.videoAssetWriterInput.expectsMediaDataInRealTime = YES;
        self.videoAssetWriterInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    }else {
        NSLog(@"can't add video input!");
        return;
    }
    
    audioInput.expectsMediaDataInRealTime = YES;
    if ([self.asseetWriter canAddInput:audioInput]) {
        [self.asseetWriter addInput:audioInput];
        self.audioAssetWriterInput = audioInput;
    }else {
        NSLog(@"can't add audio input!");
        return;
    }
    [self.asseetWriter startWriting];

}

- (void)addAudioFrame:(CMSampleBufferRef)sampleBufferRef {
    [self.asseetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBufferRef)];
    if (self.audioAssetWriterInput.readyForMoreMediaData) {
        [self.audioAssetWriterInput appendSampleBuffer:sampleBufferRef];
    }
}

- (void)addVideoFrame:(CMSampleBufferRef)sampleBufferRef {
    [self.asseetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBufferRef)];
    if (self.videoAssetWriterInput.readyForMoreMediaData) {
        [self.videoAssetWriterInput appendSampleBuffer:sampleBufferRef];
    }
}

- (void)stopRecord {
    [self.videoAssetWriterInput markAsFinished];
    [self.audioAssetWriterInput markAsFinished];
    [self.asseetWriter finishWritingWithCompletionHandler:^{
        
    }];
}

@end
