#import "MPCPlayerResponseItem.h"
#import "MPCPlayerReorderItemsCommand.h"
#import "MPCPlayerShuffleCommand.h"
#import "MPCPlayerResetTracklistCommand.h"
#import "MPCPlayerInsertItemsCommand.h"

#import "../MediaPlayer/MPSectionedCollection.h"

@interface MPCPlayerResponseTracklist
@property (nonatomic,readonly) MPCPlayerResponseItem *playingItem;
@property (nonatomic,copy,readonly) MPSectionedCollection *items;
-(id<MPCPlayerReorderItemsCommand>)reorderCommand;
-(id<MPCPlayerShuffleCommand>)shuffleCommand;
-(id<MPCPlayerResetTracklistCommand>)resetCommand;
-(id<MPCPlayerInsertItemsCommand>)insertCommand;
@end