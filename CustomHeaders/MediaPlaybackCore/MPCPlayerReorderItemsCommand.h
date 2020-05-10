#import "MPCPlayerResponseItem.h"

@protocol MPCPlayerReorderItemsCommand
- (id)moveItem:(MPCPlayerResponseItem *)targetItem afterItem:(MPCPlayerResponseItem *)positionalItem;

- (bool)canMoveItem:(id)arg1;
@end