#import "../CustomHeaders/MediaPlayer/MPRequestResponseController.h"
#import <MediaPlayer/MPMusicPlayerQueueDescriptor.h>

@interface BQPlayerController : NSObject
@property(nonatomic, retain) MPRequestResponseController *controller;

- (instancetype)initWithRequestController:(MPRequestResponseController *)controller;

- (BOOL)playItemsNext:(NSArray<MPMediaItem *> *)songs;
- (BOOL)moveQueueItemsToPlayNext:(NSArray<NSNumber *> *)itemsIndices;
- (BOOL)stopQueueAtIndex:(NSInteger)index;
- (void)shuffleQueue;

- (NSArray<MPMusicPlayerQueueDescriptor *> *)queueDescriptorsForItems:(NSArray<MPMediaItem *> *)songs;
- (BOOL)performRequest:(id)request;
- (MPCPlayerResponseTracklist *)getTracklist;

#pragma mark override
- (void)dealloc;
@end