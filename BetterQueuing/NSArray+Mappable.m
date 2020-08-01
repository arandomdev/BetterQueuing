#import "NSArray+Mappable.h"

@implementation NSArray (Mappable)
- (NSArray *)mapObjectsUsingBlock:(id (^)(id obj, NSUInteger index))block {
	NSMutableArray *result = [NSMutableArray new];
	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
		[result addObject:block(obj, index)];
	}];
	return [result copy];
}
@end