//
//  ViewController.m
//  AVAudioPlayer测试
//
//  Created by 王二 on 17/6/8.
//  Copyright © 2017年 mbs008. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MusicModel.h"

#define UI_SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define UI_SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height


static CGFloat const voluneIncrement = 0.1;

@interface ViewController ()<AVAudioPlayerDelegate>
/**
 *  底部图片
 */
@property (nonatomic, strong) UIImageView *bottomImageView;

@property (strong, nonatomic) IBOutlet UILabel *playedTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *restPlayingTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *singerAndSongLabel;
@property (strong, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *nextMusicBtn;

@property (strong, nonatomic) IBOutlet UIButton *previousMusicBtn;
@property (strong, nonatomic) IBOutlet UIImageView *musicImageView;

@property (nonatomic , strong) AVAudioPlayer *player;

/**
 当前模型数据
 */
@property (nonatomic, strong) MusicModel *currentMusicModel;
/**
 *  模型数组
 */
@property (nonatomic, strong) NSMutableArray *musicModels;
/**
 *  计时器(AVAudioPlayer代理方法里没有提供实时变化的方法，需自己写计时器去更新状态）
 */
@property (nonatomic, strong) NSTimer *timer;

/**
 记录音量
 */
@property (assign, nonatomic) CGFloat currentVolume;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self initData];
    [self initView];
    [self setPlayingInfoInBackgroud];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)initData {
    self.currentVolume = self.player.volume;
}

- (void)initView {
    [self.view insertSubview:self.bottomImageView atIndex:0];
    [self addBlurUI];
    [self updateMusicRelatedView];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"暂停"] forState:UIControlStateSelected];
}

- (void)addBlurUI {
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:self.bottomImageView.bounds];
    toolBar.barStyle = UIBarStyleBlack;
    [self.bottomImageView addSubview:toolBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    //    接受远程控制
    [self becomeFirstResponder];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)viewDidDisappear:(BOOL)animated {
    //    取消远程控制
    [self resignFirstResponder];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

#pragma mark - 业务类

- (void)updateMusicRelatedView {
    self.playedTimeLabel.text = [self formatStringWithTimeInterval:self.player.currentTime];
    self.restPlayingTimeLabel.text = [self formatStringWithTimeInterval:self.player.duration];
    self.singerAndSongLabel.text = [NSString stringWithFormat:@"%@ - %@", self.currentMusicModel.singer,self.currentMusicModel.song];
    self.slider.value = self.currentVolume;
    self.progressView.progress = 0;
    self.musicImageView.image = [UIImage imageNamed:self.currentMusicModel.imageString];
}

- (void)playMusicWithIndex:(NSInteger)index {
    MusicModel *currentMusicModel = self.musicModels[index];
    if (currentMusicModel != self.currentMusicModel) {// 如果不是是同一首
        // 停止播放，并停掉计时器，播放器置空
        [self.player pause];
        [self pauseTimer];
        self.player = nil;
        // 播放数据更新
        self.currentMusicModel = currentMusicModel;
        // 更新界面相关值，播放音乐，计时器工作
        [self updateMusicRelatedView];
        [self play];
        [self resumeTimer];
    }
    // 设置后台播放时的信息
    [self setPlayingInfoInBackgroud];
}

- (NSString *)formatStringWithTimeInterval:(NSTimeInterval)timeInteral {
    NSString *string = @"";
    
    NSInteger time = timeInteral;
    
    NSInteger hour = time / 60;
    NSInteger minute = time % 60;
    string = [NSString stringWithFormat:@"%02ld:%02ld", (long)hour, (long)minute];
    
    return string;
}

/**
 设置后台播放时显示的东西
 */
- (void)setPlayingInfoInBackgroud {
    //    设置后台播放时显示的东西，例如歌曲名字，图片等
    //    <MediaPlayer/MediaPlayer.h>
    MPMediaItemArtwork *artWork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:self.currentMusicModel.imageString]];
    
    NSDictionary *dic = @{MPMediaItemPropertyTitle:self.currentMusicModel.song,
                          MPMediaItemPropertyArtist:self.currentMusicModel.singer,
                          MPMediaItemPropertyArtwork:artWork,
                          MPMediaItemPropertyPlaybackDuration:@(self.player.duration)
                          };
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dic];
}

- (void)pause {
    [self.player pause];
    self.playOrPauseBtn.selected = NO;
}

- (void)play {
    [self.player play];
    self.playOrPauseBtn.selected = YES;
}

#pragma mark - action

- (IBAction)voluneBtnAdd:(UIButton *)sender {
    self.player.volume += voluneIncrement;
    
    if (self.player.volume >=1.0) {
        self.player.volume = 1.0;
    }
    
    self.slider.value = self.player.volume;
}

- (IBAction)voluneBtnReduce:(UIButton *)sender {
    self.player.volume -= voluneIncrement;
    
    if (self.player.volume <= 0) {
         self.player.volume = 0;
    }
    
    self.slider.value = self.player.volume;
}

- (IBAction)sliderValueChange:(UISlider *)sender {
    self.player.volume = sender.value;
    self.currentVolume = self.player.volume;
}

- (IBAction)previousMusicBtnTouch:(UIButton *)sender {
    NSInteger index = [self.musicModels indexOfObject:self.currentMusicModel];
    
    index--;
    
    if (index < 0) {
        index = self.musicModels.count - 1;
    }
    
    [self playMusicWithIndex:index];
}

- (IBAction)nextMusicBtnTouch:(UIButton *)sender {
    NSInteger index = [self.musicModels indexOfObject:self.currentMusicModel];
    
    index++;
    
    if (index >= self.musicModels.count) {
        index = 0;
    }
    
    [self playMusicWithIndex:index];
}

- (IBAction)playOrPauseBtnTouch:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        if (!self.player.isPlaying) {
            [self.player play];
            [self resumeTimer];
        }
    }
    else {
        if (self.player.isPlaying) {
            [self.player pause];
            [self pauseTimer];
        }
    }
    
    self.slider.value = self.player.volume;
}

/**
 *  一旦输出改变则执行此方法
 *
 *  @param notification 输出改变通知对象
 */
-(void)routeChange:(NSNotification *)notification{
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self.player pause];
            self.playOrPauseBtn.selected = NO;
        }
    }
}

#pragma mark - getter

- (AVAudioPlayer *)player {
    if (!_player) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:self.currentMusicModel.musicName withExtension:@"mp3"];
        _player = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
        _player.delegate = self;
        
        //添加通知，拔出耳机后暂停播放
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        
        //设置锁屏仍能继续播放
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
    }
    
    [_player prepareToPlay];
    
    return _player;
}

- (MusicModel *)currentMusicModel {
    if (!_currentMusicModel) {
        _currentMusicModel = [MusicModel new];
        _currentMusicModel.imageString = @"Maroon5.jpg";
        _currentMusicModel.song = @"Sugar";
        _currentMusicModel.singer = @"Maroon5";
        _currentMusicModel.musicName = @"Maroon 5-Sugar";

    }
    
    return _currentMusicModel;
}

- (NSMutableArray *)musicModels {
    if (!_musicModels) {
        _musicModels = [NSMutableArray new];
        MusicModel *musicModel2 = [MusicModel new];
        musicModel2.imageString = @"吴亦凡.jpg";
        musicModel2.song = @"时间煮雨";
        musicModel2.singer = @"吴亦凡";
        musicModel2.musicName = @"吴亦凡-时间煮雨";
        
        [_musicModels addObject:self.currentMusicModel];
        [_musicModels addObject:musicModel2];
    }
    
    return _musicModels;
}

- (UIImageView *)bottomImageView {
    if (!_bottomImageView) {
        _bottomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, UI_SCREEN_WIDTH, UI_SCREEN_HEIGHT)];
        _bottomImageView.image = [UIImage imageNamed:self.currentMusicModel.imageString];
    }
    
    return _bottomImageView;
}

#pragma mark - timer

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
        _timer.fireDate = [NSDate distantFuture];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
    }
    
    return _timer;
}

- (void)pauseTimer {
    if (self.timer && self.timer.isValid) {
        self.timer.fireDate = [NSDate distantFuture];
    }
}

- (void)resumeTimer {
    if (self.timer && self.timer.isValid) {
        self.timer.fireDate = [NSDate date];
        [self.timer fire];
    }
}

- (void)updateProgress {
    //进度条显示播放进度
    self.progressView.progress = self.player.currentTime/self.player.duration;
    self.playedTimeLabel.text = [self formatStringWithTimeInterval:self.player.currentTime];

}

#pragma mark - 接收方法的设置

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {  //判断是否为远程控制
        switch (event.subtype) {
            case  UIEventSubtypeRemoteControlPlay:
                if (![_player isPlaying]) {
                    [_player play];
                }
                break;
            case UIEventSubtypeRemoteControlPause:
                if ([_player isPlaying]) {
                    [_player pause];
                }
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if ([self.player isPlaying]) {
                    [self pause];
                }
                else {
                    [self play];
                }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self nextMusicBtnTouch:self.nextMusicBtn];
                NSLog(@"下一首");
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self previousMusicBtnTouch:self.previousMusicBtn];
                NSLog(@"上一首 ");
                break;
            default:
                break;
        }
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag {
    //播放结束时执行的动作
    NSLog(@"%s", __func__);
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError *)error {
    //解码错误执行的动作
     NSLog(@"%s", __func__);
}

- (void)audioPlayerBeginInteruption:(AVAudioPlayer*)player {
    //处理中断的代码
    NSLog(@"%s", __func__);
}

- (void)audioPlayerEndInteruption:(AVAudioPlayer*)player {
    //处理中断结束的代码
    NSLog(@"%s", __func__);
}

@end
