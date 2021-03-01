@import Foundation;

@interface NSArray (Mappable)
- (NSArray *)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger index))block;
@end