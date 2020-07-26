#import "BQPlayerController.h"

#import "../CustomHeaders/MediaPlaybackCore/MediaPlaybackCore.h"

#import "../CustomHeaders/MediaPlayer/MPMediaItem.h"
#import "../CustomHeaders/MediaPlayer/MPMusicPlayerMediaItemQueueDescriptor.h"
#import <MediaPlayer/MPMediaItemCollection.h>
#import <MediaPlayer/MPMusicPlayerController.h>

@implementation BQPlayerController
- (id)initWithRequestController:(MPRequestResponseController *)controller {
	self = [super init];
	if (self) {
		[controller beginAutomaticResponseLoading];
		self.controller = controller;

		continueLock = [[NSCondition alloc] init];

		// listen to response changes
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(responseChanged:) name:@"BQResponseReplacedNotification" object:nil];
	}
	return self;
}

/*
	Oh boy here we go...

	To move a song in the queue, we have to use the reorder command. Which
	works by taking the target song and moving it after (played after) another
	song. Judging by it's behavior, it probably uses the index path of the
	song item to move it. Due to this, we need to make sure that the tracklist
	we are using is the absolute latest one. To do this, I gave up and basically
	had it wait for a set amount of time before continuing.

	first wait:
		Wait for the command to complete.
	second wait:
		Wait for the response to be replaced.
	third wait:
		Wait for a bit longer, just incase the response is replaced again.

	Note: This should be called in a background thread, and the zeroth index
	is the currently playing item.
*/
- (bool)moveItemAtIndex:(NSInteger)itemIndex toIndex:(NSInteger)targetIndex {
	if (itemIndex == targetIndex) {
		HBLogDebug(@"Not moving, indices identical"); // TODO: remove
		return YES;
	}

	MPCPlayerResponseTracklist *tracklist = self.controller.response.tracklist;
	MPSectionedCollection *songs = tracklist.items;

	MPCPlayerResponseItem *item = [songs itemAtIndexPath:[songs indexPathForGlobalIndex:itemIndex]];
	MPCPlayerResponseItem *targetItem = [songs itemAtIndexPath:[songs indexPathForGlobalIndex:targetIndex]];

	id<MPCPlayerReorderItemsCommand> reorderCommand = [tracklist reorderCommand];
	if (![reorderCommand canMoveItem:item]) {
		return NO;
	}
	id reorderRequest = [reorderCommand moveItem:item afterItem:targetItem];

	// First wait
	commandSuccessful = YES;

	dispatch_semaphore_t completion = dispatch_semaphore_create(0);
	[MPCPlayerChangeRequest performRequest:reorderRequest completion:^void (NSError *error) {
		if (error) {
			HBLogError(@"Reorder Error: %@", error);
			commandSuccessful = NO;
		}
		dispatch_semaphore_signal(completion);
	}];
	dispatch_semaphore_wait(completion, DISPATCH_TIME_NOW);

	if (!commandSuccessful) {
		return NO;
	}

	// Second wait
	[continueLock lock];
	shouldContinue = NO;
	while (!shouldContinue) {
		[continueLock wait];
	}
	[continueLock unlock];

	// I LITERALLY DO NOT UNDERSTAND!!!!!!!! >:c (;n;)
	// Third wait
	[NSThread sleepForTimeInterval:0.1];

	HBLogDebug(@"moved song: <%@> after: <%@>", item.metadataObject.song.title, targetItem.metadataObject.song.title);
	return YES;
}

// To shuffle the queue, we can basically turn shuffle off and on.
- (void)shuffleQueue {
	id<MPCPlayerShuffleCommand> shuffleOffCommand = [self.controller.response.tracklist shuffleCommand];
	id offRequest = [shuffleOffCommand setShuffleType:0];
	[MPCPlayerChangeRequest performRequest:offRequest completion:^void (NSError *error) {
		
		id<MPCPlayerShuffleCommand> shuffleOnCommand = [self.controller.response.tracklist shuffleCommand];
		id onRequest = [shuffleOnCommand setShuffleType:1];
		[MPCPlayerChangeRequest performRequest:onRequest completion:nil];
	}];
}

/*
	This method works by replacing the queue with songs from the playing item and to the
	item at the given index. It also sets the playing item's elapsed time and the
	shuffle mode so that it is a seamless change (With a small pause). 
*/
- (void)stopAtIndex:(NSInteger)index {
	// include the current song
	index++;

	MPSectionedCollection *tracklist = self.controller.response.tracklist.items;
	NSInteger nowPlayingOffset = self.controller.response.tracklist.playingItem.indexPath.row;

	NSMutableArray *songs = [NSMutableArray new];
	for (NSInteger i = 0; i <= index; i++) {
		NSIndexPath *songPath = [
			NSIndexPath
			indexPathForRow: i + nowPlayingOffset
			inSection: 0
		];
		MPCPlayerResponseItem *item = [tracklist itemAtIndexPath:songPath];
		[songs addObject: [MPMediaItem itemFromSong:item.metadataObject.song]];
	}

	MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:songs];
	MPMusicPlayerMediaItemQueueDescriptor *queueDescriptor = [[MPMusicPlayerMediaItemQueueDescriptor alloc] initWithItemCollection:collection];

	double currentTime = MPMusicPlayerController.systemMusicPlayer.currentPlaybackTime;
	[queueDescriptor setStartTime:currentTime forItem:songs[0]];
	queueDescriptor.shuffleType = 0;

	MPCPlaybackIntent *intent = [MPCPlaybackIntent intentFromQueueDescriptor:queueDescriptor];
	
	id<MPCPlayerResetTracklistCommand> resetCommand = [self.controller.response.tracklist resetCommand];
	id replaceRequest = [resetCommand replaceWithPlaybackIntent:intent];
	[MPCPlayerChangeRequest performRequest:replaceRequest completion:nil];
}

- (void)responseChanged:(NSNotification *)note {
	[continueLock lock];
	shouldContinue = YES;
	[continueLock signal];
	[continueLock unlock];
}

#pragma mark override
- (void)dealloc {
	[self.controller endAutomaticResponseLoading];
}
@end