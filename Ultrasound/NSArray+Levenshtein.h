//
//  NSArray+Levenshtein.h
//  Ultrasound
//
//  Created by AppDev on 8/2/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Levenshtein)
- (NSUInteger)levenshteinDistanceToArray:(NSArray *)array;
- (double)percentErrorToReceivedArray:(NSArray *)array;

@end
