//
//  AudioPlayer.m
//  Ultrasound
//
//  Created by AppDev on 10/21/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "AudioPlayer.h"
#import "Processor.h"
#import "NSArray+Levenshtein.h"

@interface AudioPlayer ()
{
    float *frequenciesToSend;
    float *oldTransmittingFrequencies;
}

@property (nonatomic, strong) AudioManager *audio;
@property (nonatomic) double theta;
@property (nonatomic) double frequency;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) double t;
@property (nonatomic, strong) NSTimer *FFTTimer;
@property (nonatomic, strong) NSTimer *transmitTimer;
@property BOOL frequenciesChanging;

@property (nonatomic) int sequenceIndex;

@property (nonatomic) BOOL isTransmittingDelimiter;

@property (nonatomic) NSMutableArray *receivedPacketData;

@property (nonatomic) BOOL recentlyDelimited;
@property (nonatomic) BOOL hasHeardPacketDelimiter;

@property (nonatomic, strong) NSString *testString;
@end

@implementation AudioPlayer


AudioPlayer *sharedPlayer;
+ (AudioPlayer *) sharedAudioPlayer
{
    if(sharedPlayer == nil)
    {
        sharedPlayer = [[AudioPlayer alloc] init];
    }
    return sharedPlayer;
}

- (void) transmitPacketDelimiterWithCallback:(void (^)(void))callback
{
    self.isTransmittingDelimiter = YES;
    for(int i = 0; i < kNumberOfTransmitFrequencies; i++)
    {
        frequenciesToSend[i] = 0;
    }
    
    __weak AudioPlayer *weakSelf = self;
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        weakSelf.isTransmittingDelimiter = NO;
        if(callback)
        {
            callback();
        }
    });
}

- (void) setDataToTransmit: (int) numberToSend
{
    self.frequenciesChanging = YES;
    
    currentFrame = 0;
    if(frequenciesToSend != NULL)
    {
        if(oldTransmittingFrequencies != NULL)
        {
            free(oldTransmittingFrequencies);
        }
        oldTransmittingFrequencies = malloc(sizeof(float) * kNumberOfTransmitFrequencies);
        
        memcpy(oldTransmittingFrequencies, frequenciesToSend, sizeof(float) * kNumberOfTransmitFrequencies);
    }
    
    NSArray *dataToSend = [self convertByteToBoolData:numberToSend];
    NSArray *frequencies = [self frequenciesUsedForTransmitting];
    NSLog(@"%@", dataToSend);
    
    for (int i = 0; i < dataToSend.count; i++)
    {
        if ([dataToSend[i] boolValue])
        {
            frequenciesToSend[i] = [frequencies[i] floatValue];
        }
        else
        {
            frequenciesToSend[i] = 0.0f;
        }
    }
    
    r0 = arc4random();
    r1 = arc4random();
    
    self.frequenciesChanging = NO;
    [self.transmitDelegate audioStartedTransmittingFrequencies:frequenciesToSend withSize:kNumberOfTransmitFrequencies];
}

BOOL first = YES;
- (void) transmitSequence:(NSArray *)sequence
{
    NSLog(@"Transmitted nibble sequence: %@", sequence);
    [self.transmitDelegate audioStartedTransmittingSequence:frequenciesToSend withSize:kNumberOfTransmitFrequencies];

    if(first)
    {
        __weak AudioPlayer *weakSelf = self;
        [self transmitPacketDelimiterWithCallback:^{
            weakSelf.sequenceIndex = 0;
            weakSelf.transmitTimer = [NSTimer timerWithTimeInterval:kTransmitInterval target:weakSelf selector:@selector(updateTransmitSequence:) userInfo:sequence repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:weakSelf.transmitTimer forMode:NSRunLoopCommonModes];
            
            [weakSelf updateTransmitSequence:weakSelf.transmitTimer];
        }];
        first = NO;
    }
    else
    {
        self.sequenceIndex = 0;
        self.transmitTimer = [NSTimer timerWithTimeInterval:kTransmitInterval target:self selector:@selector(updateTransmitSequence:) userInfo:sequence repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.transmitTimer forMode:NSRunLoopCommonModes];
        
        [self updateTransmitSequence:self.transmitTimer];
    }
}

- (void) transmitString:(NSString *)string
{
    // Encrypt string using key
    NSString *key = @"my key";
//    NSArray *nibbles = [Processor encodeStringAndEncrypt:string withKey:key];
    NSArray *nibbles = [Processor encodeString:string];
    [self transmitSequence:nibbles];
}

- (void) updateTransmitSequence:(NSTimer *)timer
{
    NSArray *seq = timer.userInfo;
    if(self.sequenceIndex >= seq.count)
    {
        [self.transmitTimer invalidate];
        [self transmitPacketDelimiterWithCallback:^{
            [self.transmitDelegate audioFinishedTransmittingSequence];
//            [self stop];
        }];
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
        
        
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Test Strings" ofType:@"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        self.testString = dict[@"transmitString"];
    }
    
    return self;
}


double err_s = 0.0;
int err_c = 0;

- (void) getTransmittedData
{
    NSArray *frequenciesToCheck = [self frequenciesUsedForTransmitting];
    NSArray *receivedData = [self.audio fourier:frequenciesToCheck];
    if(receivedData == nil && !self.recentlyDelimited) // Delimiter was detected
    {
        NSLog(@"Processing packet");
        
//        // Print out collected packet
//        for(int i = 0; i < self.receivedPacketData.count; i++)
//        {
//            printf("%d,%d\n", i, [self.receivedPacketData[i] intValue]);
//        }
        if(self.receivedPacketData.count > 10)
        {
            NSArray *result = [Processor processPacketData:self.receivedPacketData];
//            NSLog(@"Received nibble sequence: %@", result);
            
            if(result.count % 2 == 1)
            {
                [(NSMutableArray *)(result = [result mutableCopy]) removeObjectAtIndex:0];
                NSLog(@"Removed first nibble");
            }

            if(result.count > 4)
            {
                NSArray *correctNibbles = [Processor encodeString:self.testString];
                double error = [correctNibbles percentErrorToReceivedArray:result];
                if(error > 0.8)
                {
                    printf("BAD TRANSMISSION!\n");
                    NSLog(@"Should have been nibbles: %@", correctNibbles);
                    NSLog(@"Received nibbles: %@", result);
                }
                printf("Error = %f\n", error);
                if(error == 0)
                {
                    printf("Perfect transmission! :)\n");
                }
                err_s += error;
                err_c++;
                
                printf("Error Average = %f\n", err_s / err_c);
            }
            
            NSString *receivedText = [Processor decodeData:result];
                       
            NSLog(@"%@", receivedText);
            [self.receiveDelegate audioReceivedText:receivedText];
        }
        
        [self.receivedPacketData removeAllObjects];
        
        self.recentlyDelimited = YES;
        self.hasHeardPacketDelimiter = NO;
        
        return;
    }
    else if(receivedData != nil && self.recentlyDelimited)
    {
        self.hasHeardPacketDelimiter = YES;
        NSLog(@"Starting packet");
    }
    
    if(self.hasHeardPacketDelimiter)
    {
        int byte = (int)[self convertBoolDataToByte:receivedData];
        [self.receiveDelegate audioReceivedDataUpdate:byte];
        [self.receivedPacketData addObject:@(byte)];
        
//        NSLog(@"Adding byte to packet array");
        
        self.recentlyDelimited = NO;
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
    return kTransmitFrequencies;
}


#define DEBUG_AUDIO_PLAYBACK 0
const double gf0 = 18100 * M_PI * 2;
const double gf1 = 18300 * M_PI * 2;
const double gf2 = 18900 * M_PI * 2;
const double gf3 = 19700 * M_PI * 2;

u_int32_t r0 = 0;
u_int32_t r1 = 0;

double audioFunction(double t, float *frequenciesToSend)
{
#if DEBUG_AUDIO_PLAYBACK == 1
    return sin(t * 587.33);
#endif
    
    if(frequenciesToSend == NULL) return 0;
    
    double sum = 0.0;
    double divisor = 0;
    for (int i = 0; i < kNumberOfTransmitFrequencies; i++)
    {
        double freq = frequenciesToSend[i];
        sum += sin(t * freq) * amplitudeAdjustments[i];
        divisor += freq > 1 ? 1 : 0;
    }
    
    
    /*if(r0 < UINT32_MAX / 4)
    {
        sum += sin(t * gf0);
    }
    else if(r0 >= UINT32_MAX / 4 && r0 < UINT32_MAX / 2)
    {
        sum += sin(t * gf1);
    }
    else if(r0 > UINT32_MAX / 2 && r0 < (u_int32_t)(UINT32_MAX * 0.75))
    {
        sum += sin(t * gf2);
    }
    else
    {
        sum += sin(t * gf3);
    }
    divisor++;
    
    
    
    if(r1 < UINT32_MAX / 4)
    {
        sum += sin(t * gf2);
    }
    else if(r1 >= UINT32_MAX / 4 && r1 < UINT32_MAX / 2)
    {
        sum += sin(t * gf0);
    }
    else if(r1 > UINT32_MAX / 2 && r1 < (u_int32_t)(UINT32_MAX * 0.75))
    {
        sum += sin(t * gf3);
    }
    else
    {
        sum += sin(t * gf1);
    }
    divisor++;*/
    
    /*sum += sin(t * gf1);
    divisor++;*/
    
    if(divisor == 0)
    {
        return 0;
    }
    
    
    return sum / divisor;
}


float amplitudeAdjustmentsIPadTransmit[] = {4.0, 4.0, 10.0, 20.0}; // Arbitrary numbers to boost certain frequencies by (experimentally determined)
float amplitudeAdjustmentsITouchTransmit[] = {1.0, 1.0, 1.0, 1.0}; // Arbitrary numbers to boost certain frequenci  es by (experimentally determined)
float *amplitudeAdjustments; // Set at runtime for specific device;

int currentFrame = 0;
double maxCallCount = 14592.0 * (kTransmitInterval / 0.4);

double rampUp = 0.2;
double rampDown = 0.8;

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
            
            self.t += 1.0 / sampleRate;
            double time = self.t * 2 * M_PI;
            
            if(self.isTransmittingDelimiter)
            {
                data[frame] = sin(time * kPacketDelimiterFrequency) * 5;
                continue;
            }
            
            
            double progress = (double) (currentFrame / (double) maxCallCount);
            double ramp = 0.0;
            if (progress <= rampUp)
            {
                ramp = progress / rampUp;
            }
            else if(progress > rampUp && progress <= rampDown)
            {
                ramp = 1.0;
            }
            else
            {
                ramp = 1.0 - (progress - rampDown) / (1.0 - rampDown);
            }
            ramp = MIN(ramp, 1.0);
            ramp = MAX(ramp, 0.0);
            
            data[frame] = audioFunction(time, frequenciesToSend) * ramp;
            currentFrame++;
        }
    }
}

- (void) fftData:(float *)data arraySize:(int)size cutoff:(float)cutoff
{
    [self.receiveDelegate audioReceivedFFTData:data arraySize:size cutoff:cutoff];
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
