//
//  UltrasoundTests.m
//  UltrasoundTests
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "UltrasoundTests.h"
#import "Processor.h"
#include "ProcessingFunctionsC.h"
#import "NSArray+Levenshtein.h"

@implementation UltrasoundTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{    
    [super tearDown];
}

#pragma mark - Helper Methods
- (NSArray *) getRandomBytes
{
    int len = (rand() % 10000) + 1;
    NSMutableArray *bytes = [NSMutableArray arrayWithCapacity:len];
    for(int i = 0; i < len; i++)
    {
        [bytes addObject:@(rand() % 100)];
    }
    return bytes;
}

#pragma mark - Test Cases
- (void) testStringEncoding
{
    NSString *string = @"Marry had a little lab";
    NSArray *data = [Processor encodeString:string];
    NSString *result = [Processor decodeData:data];
    
    STAssertEqualObjects(string, result, @"Original string and encoded then decoded string should be equal");
}

- (void) testNibblesToBytes
{
    for(int i = 0; i < 10; i++)
    {
        NSArray *originalBytes = [self getRandomBytes];
        NSArray *nibbles = [Processor splitByteArrayIntoNibbleArray:originalBytes];
        NSArray *newBytes = [Processor combineNibbleArrayToByteArray:nibbles];
        STAssertEqualObjects(originalBytes, newBytes, @"Stuff is not equal");
    }
}

- (void) testEncryption
{
    NSString *plainText = @"Hello, world";
    NSString *key = @"asdfsdfadf";
    NSArray *encryptedData = [Processor encodeStringAndEncrypt:plainText withKey:key];
    NSString *plainData = [Processor decodeDataAndDecrypt:encryptedData withKey:key];
    STAssertEqualObjects(plainText, plainData, @"Encrypted and decrypted strings are not the same");
}

- (void) testPercentError
{
    NSArray *correct = @[@5, @9, @8, @2, @3, @9];
    NSArray *received = @[@5, @8, @2, @2, @3, @9, @3, @2];
    double error = [correct percentErrorToReceivedArray:received];
    
    STAssertEqualsWithAccuracy(error, 4.0/6.0, 0.001, @"The error should equal 4/6, 0.6666");
}


@end
