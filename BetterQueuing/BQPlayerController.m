#import "BQPlayerController.h"
#import "BQSongProvider.h"
#import "NSArray+Mappable.h"

#import "../CustomHeaders/MediaPlaybackCore/MediaPlaybackCore.h"
#import "../CustomHeaders/MediaPlayer/MediaPlayer.h"

#import <MediaPlayer/MPMediaItemCollection.h>
#import <MediaPlayer/MPMusicPlayerController.h>

@implementation BQPlayerController

- (instancetype)initWithRequestController:(MPRequestResponseController *)controller {
	self = [super init];
	if (self) {
		self.controller = controller;
		[controller beginAutomaticResponseLoading];
	}
	return self;
}

- (BOOL)playItemsNext:(NSArray<MPMediaItem *> *)items {
	NSArray<MPMusicPlayerQueueDescriptor *> *descriptors = [self queueDescriptorsForItems:items];
	BOOL allSuccessful = YES;
	
	for (MPMusicPlayerQueueDescriptor *descriptor in [descriptors reverseObjectEnumerator]) {
		descriptor.shuffleType = 0;

		MPCPlaybackIntent *intent = [MPCPlaybackIntent intentFromQueueDescriptor:descriptor];
		id insertRequest = [[[self getTracklist] insertCommand] insertAfterPlayingItemWithPlaybackIntent:intent];
		allSuccessful = [self performRequest:insertRequest] ? allSuccessful : NO;
	}

	return allSuccessful;
}


- (BOOL)moveQueueItemsToPlayNext:(NSArray<NSNumber *> *)itemsIndices {
	MPSectionedCollection *songCollection = [self getTracklist].items;
	NSArray *targetItems = [itemsIndices mapObjectsUsingBlock:^MPMediaItem *(NSNumber *itemIndex, NSUInteger index) {
		// remove the item from the queue
		MPCPlayerResponseItem *item = [songCollection itemAtIndexPath:[songCollection indexPathForGlobalIndex:itemIndex.integerValue]];
		[MPCPlayerChangeRequest performRequest:[item remove] completion:nil];

		return [MPMediaItem itemFromSong:item.metadataObject.song];
	}];

	BOOL allSuccessful = YES;

	// re-insert the songs at the top
	NSArray<MPMusicPlayerQueueDescriptor *> *descriptors = [self queueDescriptorsForItems:targetItems];
	for (MPMusicPlayerQueueDescriptor *descriptor in [descriptors reverseObjectEnumerator]) {
		descriptor.shuffleType = 0;

		MPCPlaybackIntent *intent = [MPCPlaybackIntent intentFromQueueDescriptor:descriptor];
		id insertRequest = [[[self getTracklist] insertCommand] insertAfterPlayingItemWithPlaybackIntent:intent];
		allSuccessful = [self performRequest:insertRequest] ? allSuccessful : NO;
	}

	return allSuccessful;
}

- (BOOL)stopQueueAtIndex:(NSInteger)index {
	BQSongProvider *songCollection = [[BQSongProvider alloc] initWithSongs:[self getTracklist].items];
	NSMutableArray<MPMediaItem *> *targetItems = [NSMutableArray new];
	for (int i = 0; i <= index; i++) {
		[targetItems addObject:[MPMediaItem itemFromSong:[songCollection songAtIndex:i]]];
	}

	NSArray<MPMusicPlayerQueueDescriptor *> *descriptors = [self queueDescriptorsForItems:targetItems];

	// turn off shuffle to preserve the order
	for (MPMusicPlayerQueueDescriptor *descriptor in descriptors) {
		descriptor.shuffleType = 0;
	}
	
	// set the start time for the first song
	double currentTime = MPMusicPlayerController.systemMusicPlayer.currentPlaybackTime;
	if ([descriptors[0] isKindOfClass:[MPMusicPlayerMediaItemQueueDescriptor class]]) {
		MPMusicPlayerMediaItemQueueDescriptor *firstDescriptor = (MPMusicPlayerMediaItemQueueDescriptor *)descriptors[0];
		MPMediaItem *firstItem = firstDescriptor.itemCollection.items[0];
		[firstDescriptor setStartTime:currentTime forItem:firstItem];
	}
	else {
		MPMusicPlayerStoreQueueDescriptor *firstDescriptor = (MPMusicPlayerStoreQueueDescriptor *)descriptors[0];
		NSString *firstItem = firstDescriptor.storeIDs[0];
		[firstDescriptor setStartTime:currentTime forItemWithStoreID:firstItem];
	}

	BOOL allSuccessful = YES;
	
	// reset the queue with the first descriptor
	MPCPlaybackIntent *firstIntent = [MPCPlaybackIntent intentFromQueueDescriptor:descriptors[0]];
	id replaceRequest = [[[self getTracklist] resetCommand] replaceWithPlaybackIntent:firstIntent];
	allSuccessful = [self performRequest:replaceRequest] ? allSuccessful : NO;

	// insert the rest of the descriptors
	for (int i = 1; i < descriptors.count; i++) {
		MPCPlaybackIntent *intent = [MPCPlaybackIntent intentFromQueueDescriptor:descriptors[i]];
		id insertRequest = [[[self getTracklist] insertCommand] insertAtEndOfTracklistWithPlaybackIntent:intent];
		allSuccessful = [self performRequest:insertRequest] ? allSuccessful : NO;
	}

	return allSuccessful;
}

- (void)shuffleQueue {
	id<MPCPlayerShuffleCommand> advanceRequest = [[[self getTracklist] shuffleCommand] advance];
	[MPCPlayerChangeRequest performRequest:advanceRequest completion:nil];
	[MPCPlayerChangeRequest performRequest:advanceRequest completion:nil];
}

/**
*	This method takes an array of songs and puts them into queue descriptors while
*	persevering their order. MPConcreteMediaItem (local and added to library)
*	are put into MPMusicPlayerMediaItemQueueDescriptors
*	while MPModelObjectMediaItem (non-local and probably not added to library) are
*	put into MPMusicPlayerStoreQueueDescriptors.
*/
- (NSArray<MPMusicPlayerQueueDescriptor *> *)queueDescriptorsForItems:(NSArray<MPMediaItem *> *)items {
	if (items.count == 0) {
		return @[];
	}

	// First find where we need to split the songs array.
	// These markers are placed when a MPConcreteMediaItem
	// is next to a MPModelObjectMediaItem.

	NSMutableArray<NSNumber *> *splitPoints = [NSMutableArray new];
	for (int i = 1; i < items.count; i++) {
		BOOL isItem1Local = ![items[i-1] isKindOfClass:[MPModelObjectMediaItem class]];
		BOOL isItem2Local = ![items[i] isKindOfClass:[MPModelObjectMediaItem class]];
		
		// XOR
		if (isItem1Local ^ isItem2Local) {
			[splitPoints addObject:@(i)];
		}
	}
	[splitPoints addObject:@(items.count)];

	// Then using the split points, split the songs
	NSMutableArray<MPMusicPlayerQueueDescriptor *> *songDescriptors = [NSMutableArray new];
	NSInteger songHead = 0;
	for (NSNumber *point in splitPoints) {
		NSRange arrayRange = NSMakeRange(songHead, point.integerValue-songHead);
		NSArray<MPMediaItem *> *sectionedSongs = [items subarrayWithRange:arrayRange];
		songHead = point.integerValue;

		// put the sectioned songs into a descriptor
		if ([sectionedSongs[0] isKindOfClass:[MPModelObjectMediaItem class]]) {
			// Use store id
			NSMutableArray<NSString *> *storeIDs = [NSMutableArray new];
			for (MPMediaItem *songItem in sectionedSongs) {
				[storeIDs addObject:songItem.playbackStoreID];
			}
			[songDescriptors addObject:[[MPMusicPlayerStoreQueueDescriptor alloc] initWithStoreIDs: storeIDs]];
		}
		else {
			// Use MPMediaItem
			MPMediaItemCollection *songCollection = [MPMediaItemCollection collectionWithItems:sectionedSongs];
			[songDescriptors addObject:[[MPMusicPlayerMediaItemQueueDescriptor alloc] initWithItemCollection:songCollection]];
		}
	}

	return [songDescriptors copy];
}

- (BOOL)performRequest:(id)request {
	__block BOOL isCommandSuccessful = YES;
	
	// Wait for the command to send
	dispatch_semaphore_t completion = dispatch_semaphore_create(0);
	[MPCPlayerChangeRequest performRequest:request completion:^void (NSError *error) {
		if (error) {
			isCommandSuccessful = NO;
		}
		dispatch_semaphore_signal(completion);
	}];
	dispatch_semaphore_wait(completion, DISPATCH_TIME_NOW);

	if (!isCommandSuccessful) {
		return NO;
	}

	// wait for the response to change
	__block BOOL responseChanged = NO;
	NSNotificationCenter * __weak center = [NSNotificationCenter defaultCenter];
	id __block token = [center addObserverForName:@"BQResponseReplacedNotification" object:nil queue:nil usingBlock:^(NSNotification *note) {
		responseChanged = YES;
		[center removeObserver:token];
	}];

	NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:1];
	while (!responseChanged) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		if ([timeoutDate compare:[NSDate date]] == NSOrderedAscending) {
			[center removeObserver:token];
			break;
		}
	}

	return YES;
}

- (MPCPlayerResponseTracklist *)getTracklist {
	return self.controller.response.tracklist;
}

#pragma mark override
- (void)dealloc {
	[self.controller endAutomaticResponseLoading];
}
@end