#import "MPCPlayerResponseItem.h"

@protocol MPCPlayerReorderItemsCommand
- (id)moveItem:(MPCPlayerResponseItem *)targetItem afterItem:(MPCPlayerResponseItem *)positionalItem;
@end