//
//  ViewController.m
//  ESCRecordMP4Demo
//
//  Created by xiang on 2018/6/23.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "ESCRecordMP4Tool.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property(nonatomic,strong)AVCaptureSession* captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic,strong)AVCaptureAudioDataOutput *audioDataOutput;

@property(nonatomic,strong)dispatch_queue_t videoAndAudioDataOutputQueue;

@property(nonatomic,assign)BOOL isRecording;

@property(nonatomic,strong)NSDateFormatter* dateFormatter;

@property(nonatomic,strong)ESCRecordMP4Tool* recordMP4Tool;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prapareToRecord];
}

- (void)prapareToRecord {
    [self initBaseSession];
    [self addAudioInputAndOutput];
    [self addVideoInputAndOutput];
}

- (void)initBaseSession {
    self.captureSession = [[AVCaptureSession alloc] init];
    dispatch_queue_t videoAndAudioDataOutputQueue = dispatch_queue_create("videoAndAudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    self.videoAndAudioDataOutputQueue = videoAndAudioDataOutputQueue;
    
    AVCaptureVideoPreviewLayer* layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 100);
    [self.view.layer addSublayer:layer];
}

-(void)addVideoInputAndOutput{
    
    AVCaptureDevice* video = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError* error;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:video error:&error];
    if (error) {
        NSLog(@"创建视频输入端失败,%@",error);
        return;
    }
    
    [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    
    if (![self.captureSession canAddInput:input]) {
        NSLog(@"输入端添加失败");
        return;
    }
    [self.captureSession addInput:input];
    
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    if ([self.captureSession canAddOutput:videoDataOutput]) {
        [self.captureSession addOutput:videoDataOutput];
        self.videoDataOutput = videoDataOutput;
       
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoAndAudioDataOutputQueue];
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    }else {
        NSLog(@"添加视频输出失败");
    }
}

- (void)addAudioInputAndOutput {
    AVCaptureDevice *audio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:audio error:&error];
    if (error) {
        NSLog(@"创建音频输入失败");
        return;
    }
    if (![self.captureSession canAddInput:input]) {
        NSLog(@"添加音频端失败");
        return;
    }
    [self.captureSession addInput:input];
    
    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    if ([self.captureSession canAddOutput:audioDataOutput]) {
        [self.captureSession addOutput:audioDataOutput];
        self.audioDataOutput = audioDataOutput;
        [self.audioDataOutput setSampleBufferDelegate:self queue:self.videoAndAudioDataOutputQueue];
    }else {
        NSLog(@"添加音频输出失败");
    }
}

#pragma mark - Action
- (IBAction)didClickRecordButton:(UIButton *)sender {
    if (self.isRecording) {
        [sender setTitle:@"start" forState:UIControlStateNormal];
        [self.captureSession stopRunning];
        [self.recordMP4Tool stopRecord];
        NSLog(@"结束");
    }else {
        [sender setTitle:@"stop" forState:UIControlStateNormal];
        NSLog(@"开始");
        self.recordMP4Tool = [[ESCRecordMP4Tool alloc] init];
        NSString *filePath = [self getFilePath];
        [self.recordMP4Tool startRecordWithFilePath:filePath Width:1280 height:720 frameRate:30 audioSampleRate:8000];
        [self.captureSession startRunning];
    }
    self.isRecording = !self.isRecording;
}

- (NSString *)getFilePath {
    NSString *filePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    filePath = [NSString stringWithFormat:@"%@/%@.mp4",filePath,[self.dateFormatter stringFromDate:[NSDate date]]];
    return filePath;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([output isEqual:self.audioDataOutput]) {
        NSLog(@"did get audio %@",output);
        [self.recordMP4Tool addAudioFrame:sampleBuffer];
    }else if ([output isEqual:self.videoDataOutput]) {
        NSLog(@"did get vidoe %@",output);
        [self.recordMP4Tool addVideoFrame:sampleBuffer];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0) {
    NSLog(@"did drop %@",output);
}

#pragma mark - getter
- (NSDateFormatter *)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss";
    }
    return _dateFormatter;
}
@end
