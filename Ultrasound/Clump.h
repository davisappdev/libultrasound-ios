//
//  Clump.h
//  ProcessAlgo
//
//  Created by AppDev on 7/5/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Clump : NSObject

@property (nonatomic, readonly) double average;
@property (nonatomic, readonly) int smallest;
@property (nonatomic, readonly) int biggest;

- (void) addNumber:(int) dataToAdd;
@end
