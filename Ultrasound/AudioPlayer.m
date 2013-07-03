//
//  AudioPlayer.m
//  Ultrasound
//
//  Created by AppDev on 10/21/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "AudioPlayer.h"

#define kFFTInterval 0.02
#define kTransmitInterval 0.6

@interface AudioPlayer ()
{
    float *frequenciesToSend;
}

@property (nonatomic, strong) AudioManager *audio;
@property (nonatomic) double theta;
@property (nonatomic) double frequency;
@property (nonatomic) double t;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic, strong) NSTimer *FFTTimer;
@property (nonatomic, strong) NSTimer *transmitTimer;
@property BOOL frequenciesChanging;

@property (nonatomic) int sequenceIndex;

@property (nonatomic) BOOL isTransmittingDeliminator;

@property (nonatomic) NSMutableArray *receivedPacketData;

@property (nonatomic) BOOL recentlyDeliminated;
@property (nonatomic) BOOL hasHeardPacketDeliminator;
@end

@implementation AudioPlayer


- (void) transmitPacketDeliminatorWithCallback:(void (^)(void))callback
{
    self.isTransmittingDeliminator = YES;
    for(int i = 0; i < kNumberOfTransmitFrequencies; i++)
    {
        frequenciesToSend[i] = 0;
    }
    
    __weak AudioPlayer *weakSelf = self;
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        weakSelf.isTransmittingDeliminator = NO;
        if(callback)
        {
            callback();
        }
    });
}

- (void) setDataToTransmit: (int) numberToSend
{
    self.frequenciesChanging = YES;
    NSArray *dataToSend = [self convertByteToBoolData:numberToSend];
    NSArray *frequencies = [self frequenciesUsedForTransmitting];
    NSLog(@"%@", dataToSend);
    
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
    self.frequenciesChanging = NO;
}

- (void) transmitSequence:(NSArray *)sequence
{
    __weak AudioPlayer *weakSelf = self;
    [self transmitPacketDeliminatorWithCallback:^{
        weakSelf.sequenceIndex = 0;
        weakSelf.transmitTimer = [NSTimer timerWithTimeInterval:kTransmitInterval target:weakSelf selector:@selector(updateTransmitSequence:) userInfo:sequence repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:weakSelf.transmitTimer forMode:NSRunLoopCommonModes];
        
        [weakSelf updateTransmitSequence:weakSelf.transmitTimer];
    }];
}

- (void) updateTransmitSequence:(NSTimer *)timer
{
    NSArray *seq = timer.userInfo;
    if(self.sequenceIndex >= seq.count)
    {
        [self.transmitTimer invalidate];
        [self transmitPacketDeliminatorWithCallback:nil];
        return;
    }
    
    int currentData = [seq[self.sequenceIndex] intValue];
    [self setDataToTransmit:currentData];
    
    self.sequenceIndex++;
}

- (id) init
{
    self = [super init];
    if(self)
    {
        self.audio = [[AudioManager alloc] initWithDelegate:self];
        
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            amplitudeAdjustments = amplitudeAdjustmentsITouchTransmit;
        }
        else
        {
            amplitudeAdjustments = amplitudeAdjustmentsIPadTransmit;
        }
        
        frequenciesToSend = malloc(sizeof(float) * kNumberOfTransmitFrequencies);
        self.receivedPacketData = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (void) getTransmittedData
{
    NSArray *frequenciesToCheck = [self frequenciesUsedForTransmitting];
    NSArray *receivedData = [self.audio fourier:frequenciesToCheck];
    if(receivedData == nil && !self.recentlyDeliminated) // Deliminator was detected
    {
        // Print out collected packet
        for(int i = 0; i < self.receivedPacketData.count; i++)
        {
            printf("%d,%d\n", i, [self.receivedPacketData[i] intValue]);
        }
        
        [self.receivedPacketData removeAllObjects];
        
        self.recentlyDeliminated = YES;
        self.hasHeardPacketDeliminator = NO;
        
        return;
    }
    else if(receivedData != nil && self.recentlyDeliminated)
    {
        self.hasHeardPacketDeliminator = YES;
    }
    
    if(self.hasHeardPacketDeliminator)
    {
        int byte = (int)[self convertBoolDataToByte:receivedData];
        [self.delegate audioReceivedDataUpdate:byte];
        [self.receivedPacketData addObject:@(byte)];
        
        self.recentlyDeliminated = NO;
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
    /*NSMutableArray *freqs = [NSMutableArray array];
    int step = (kUpperFrequencyBound-kLowerFrequencyBound) / kNumberOfTransmitFrequencies;
    for(int f = kLowerFrequencyBound; f <= kUpperFrequencyBound - step; f += step)
    {
        [freqs addObject:@(f)];
    }
    
    return [freqs copy];*/
    
    return @[@18000, @18150, @18600, @19500];
}


float amplitudeAdjustmentsIPadTransmit[] = {4.0, 4.0, 10.0, 15.0}; // Arbitrary numbers to boost certain frequencies by (experimentally determined)
float amplitudeAdjustmentsITouchTransmit[] = {1.0, 1.0, 1.0, 1.0}; // Arbitrary numbers to boost certain frequencies by (experimentally determined)
float *amplitudeAdjustments; // Set at runtime for specific device;
- (void) renderAudioIntoData:(Float32 *)data withSampleRate:(double)sampleRate numberOfFrames:(int)numberOfFrames
{   
    if(self.isPlaying)
    {
        for (UInt32 frame = 0; frame < numberOfFrames; frame++)
        {
            if(frequenciesToSend == NULL || self.frequenciesChanging)
            {
                data[frame] = 0;
                continue;
            }
            
            
            float sum = 0.0f;
            self.t += 1.0 / sampleRate;
            double time = self.t * 2 * M_PI;
            
            if(self.isTransmittingDeliminator)
            {
                data[frame] = sin(time * kPacketDeliminatorFrequency);
                continue;
            }
            
            
            /*data[frame] = sin(time * 587.33);
            data[frame] += sin(time * 880);*/


            float divisor = 0;
            for (int i = 0; i < kNumberOfTransmitFrequencies; i++)
            {
                double freq = frequenciesToSend[i];
                sum += sin(time * freq) * amplitudeAdjustments[i];
                divisor += freq > 1 ? 1 : 0;
            }
            
            if(divisor == 0)
            {
                data[frame] = 0;
                continue;
            }
            
            sum /= divisor;
            
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
    /*BOOL p4 = (byte & 0x10) != 0 ? YES : NO;
    BOOL p5 = (byte & 0x20) != 0 ? YES : NO;
    BOOL p6 = (byte & 0x40) != 0 ? YES : NO;
    BOOL p7 = (byte & 0x80) != 0 ? YES : NO;*/
    
    return @[@(p0), @(p1), @(p2), @(p3)];

}

- (void) start
{
    if(self.isReceiving)
    {
        [self.receivedPacketData removeAllObjects];
        self.FFTTimer = [NSTimer timerWithTimeInterval:kFFTInterval target:self selector:@selector(getTransmittedData) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.FFTTimer forMode:NSRunLoopCommonModes];
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
    [self.FFTTimer invalidate];
    self.isPlaying = NO;
    
    [self.audio stopAudio];
}

- (void) setIsReceiving:(BOOL)isReceiving
{
    _isReceiving = isReceiving;
    self.audio.isReceiving = isReceiving;
}
@end
