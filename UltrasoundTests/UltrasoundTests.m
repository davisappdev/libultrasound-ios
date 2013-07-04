//
//  UltrasoundTests.m
//  UltrasoundTests
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "UltrasoundTests.h"
#import "Processor.h"

@implementation UltrasoundTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{    
    [super tearDown];
}


- (void) testStringEncoding
{
    NSString *string = @"FOGBADJIG";
    NSArray *data = [Processor encodeString:string];
    NSString *result = [Processor decodeData:data];
    
    STAssertEqualObjects(string, result, @"Original string and encoded then decoded string should be equal");
}

@end
