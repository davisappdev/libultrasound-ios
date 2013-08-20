
#import <Foundation/Foundation.h>

@interface NSString (Levenshtein)
- (NSUInteger)levenshteinDistanceToString:(NSString *)string;
- (float)percentCorrectToString:(NSString *)string;
@end