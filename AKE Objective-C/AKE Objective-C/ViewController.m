//
//  ViewController.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/19.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "ViewController.h"
#import "AKEVideoCapure.h"
#import "AKEPreviewView.h"
#import "AKEAudioCapture.h"
#import "AKERTMPSender.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet AKEPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;

@property (strong, nonatomic) AKEVideoCapure *videoCapture;
@property (strong, nonatomic) AKEAudioCapture *audioCapture;
@property (strong, nonatomic) AKERTMPSender *rtmpSender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.urlTextField.backgroundColor = [UIColor grayColor];
    self.urlTextField.hidden = YES;

    [self.rtmpSender connect];
}

- (AKEVideoCapure *)videoCapture
{
    if (!_videoCapture) {
        _videoCapture = [AKEVideoCapure new];
    }

    return _videoCapture;
}

- (AKEAudioCapture *)audioCapture
{
    if (!_audioCapture) {
        _audioCapture = [AKEAudioCapture new];
    }

    return _audioCapture;
}

- (AKERTMPSender *)rtmpSender
{
    if (!_rtmpSender) {
        _rtmpSender = [AKERTMPSender new];
    }

    return _rtmpSender;
}

- (IBAction)onStartButtonAction:(UIButton *)sender
{
    [self.videoCapture start:self.previewView];
    [self.audioCapture start];
}

- (IBAction)onSwitchButtonAction:(UIButton *)sender
{
    [self.videoCapture switchCamera];
}

@end
