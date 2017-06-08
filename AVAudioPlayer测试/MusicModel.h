//
//  MusicModel.h
//  AVAudioPlayer测试
//
//  Created by 王二 on 17/6/8.
//  Copyright © 2017年 mbs008. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicModel : NSObject

@property (copy, nonatomic) NSString *singer;
@property (copy, nonatomic) NSString *song;
@property (copy, nonatomic) NSString *playedTime;// 04:23
@property (copy, nonatomic) NSString *restPlayingTime; // 01:23
@property (copy, nonatomic) NSString *imageString;

/**
 音乐名字
 */
@property (copy, nonatomic) NSString *musicName;



@end
