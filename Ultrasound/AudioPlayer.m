//
//  AudioPlayer.m
//  Ultrasound
//
//  Created by AppDev on 10/21/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "AudioPlayer.h"

@interface AudioPlayer ()
{
    float *frequenciesToSend;
}

@property (nonatomic, strong) AudioManager *audio;
@property (nonatomic) double theta;
@property (nonatomic) double frequency;
@property (nonatomic) double t;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation AudioPlayer

- (void) setDataToTransmit: (int) numberToSend
{
    NSArray *dataToSend = [self convertByteToBoolData:numberToSend];
    NSArray *frequencies = [self frequenciesUsedForTransmitting];
    NSLog(@"%@", dataToSend);
   
    if (frequenciesToSend)
    {
        free(frequenciesToSend);
    }
    
    frequenciesToSend = malloc(sizeof(float) * kNumberOfTransmitFrequencies);
    for (int i = 0; i < dataToSend.count; i++)
    {
        if ([dataToSend[i] boolValue])
        {
            //[tempFrequenciesToSend addObject:frequencies[i]];
            frequenciesToSend[i] = [frequencies[i] floatValue];
        }
        else
        {
            frequenciesToSend[i] = 0.0f;
        }
    }
}

- (id) init
{
    self = [super init];
    if(self)
    {
        self.audio = [[AudioManager alloc] initWithDelegate:self];
        //[self setDataToTransmit];
    }
    
    return self;
}


- (void) getTransmittedData
{
    NSArray *frequenciesToCheck = [self frequenciesUsedForTransmitting];
    NSArray *receivedData = [self.audio fourier:frequenciesToCheck];
    
    
    if(![self isDataAllZero:receivedData])
    {
        Byte byte = [self convertBoolDataToByte:receivedData];
        [self.delegate audioReceivedDataUpdate:(int)byte];
        printf("%i\n\n", (int)byte);
    }
    else
    {
        [self.delegate audioReceivedDataUpdate:0];
    }
    
}

- (BOOL) isDataAllZero:(NSArray *) data
{
    for(int i = 0; i < data.count; i++)
    {
        if([data[i] boolValue])
        {
            return NO;
        }
    }
    
    return YES;
}

- (Byte) convertBoolDataToByte:(NSArray *)data
{
    Byte sum = 0;
    for(int i = 0; i < data.count; i++)
    {
        BOOL b = [data[i] boolValue];
        if(b)
        {
            sum += pow(2, i);
        }
    }
    
    return sum;
}

- (NSArray *) frequenciesUsedForTransmitting
{
    NSMutableArray *freqs = [NSMutableArray array];
    int step = (kUpperFrequencyBound-kLowerFrequencyBound) / kNumberOfTransmitFrequencies;
    for(int f = kLowerFrequencyBound; f <= kUpperFrequencyBound - step; f += step)
    {
        [freqs addObject:@(f)];
    }
    
    return [freqs copy];
}


- (void) renderAudioIntoData:(Float32 *)data withSampleRate:(double)sampleRate numberOfFrames:(int)numberOfFrames
{   
    if(self.isPlaying)
    {
        for (UInt32 frame = 0; frame < numberOfFrames; frame++)
        {
            if(frequenciesToSend == NULL)
            {
                data[frame] = 0;
                continue;
            }
            
            float sum = 0.0f;
            self.t += 1.0 / sampleRate;
            double time = self.t * 2 * M_PI;
            for (int i = 0; i < kNumberOfTransmitFrequencies; i++)
            {
                sum += sin(time * frequenciesToSend[i]);
            }
            
            data[frame] = sum;
        }
    }

}

- (NSArray *) convertByteToBoolData:(Byte) byte
{
    /*NSMutableArray *tempBools = [NSMutableArray array];
    for(int i = 0; i < 8; i++)
    {
        BOOL b = (num & (uint)pow(2, i)) != 0 ? YES : NO;
        [tempBools addObject:@(b)];
    }
    
    return [tempBools copy];*/
    
    
    BOOL p0 = (byte & 0x01) != 0 ? YES : NO;
    BOOL p1 = (byte & 0x02) != 0 ? YES : NO;
    BOOL p2 = (byte & 0x04) != 0 ? YES : NO;
    BOOL p3 = (byte & 0x08) != 0 ? YES : NO;
    BOOL p4 = (byte & 0x10) != 0 ? YES : NO;
    BOOL p5 = (byte & 0x20) != 0 ? YES : NO;
    BOOL p6 = (byte & 0x40) != 0 ? YES : NO;
    BOOL p7 = (byte & 0x80) != 0 ? YES : NO;
    
    return [NSArray arrayWithObjects:@(p0), @(p1), @(p2), @(p3), @(p4), @(p5), @(p6), @(p7), nil];

}

- (void) start
{
    if(self.isReceiving)
    {
        self.timer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(getTransmittedData) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    else
    {
        self.isPlaying = YES;
    }
    self.audio.isReceiving = self.isReceiving;
    
    [self.audio startAudio];
}

- (void) stop
{
    [self.timer invalidate];
    self.isPlaying = NO;
    
    [self.audio stopAudio];
}

- (void) setIsReceiving:(BOOL)isReceiving
{
    _isReceiving = isReceiving;
    self.audio.isReceiving = isReceiving;
}
@end
