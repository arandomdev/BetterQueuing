#import "EMQueueDataSource.h"

#import "../CustomHeaders/MediaPlaybackCore/MPCPlayerResponseItem.h"

#import "../CustomHeaders/MediaPlayer/MPMediaItem.h"
#import "../CustomHeaders/MediaPlayer/MPArtworkCatalog.h"

@implementation EMQueueDataSource
- (instancetype)initWithResponse:(MPCPlayerResponse *)response {
	self = [super init];
	if (self) {
		[self updateWithResponse:response];
	}
	return self;
}

/*
	The data source should update it's data only when the items in the
	queue changes. To do this, we can save the content identifier for a
	song in the queue and compare it to the provided tracklist.

	The song that we use should not be the playing song because it would
	not pickup on queue changes when the shuffle action is used.
*/
- (bool)shouldUpdateWithResponse:(MPCPlayerResponse *)response {
	NSIndexPath *identifierPath = [
		NSIndexPath
		indexPathForRow: response.tracklist.playingItem.indexPath.row + 1
		inSection: 0
	];
	MPCPlayerResponseItem *identifierSong = [response.tracklist.items itemAtIndexPath: identifierPath];
	NSString *newIdentifer = identifierSong.contentItemIdentifier;

	if ([newIdentifer isEqual:self.queueIdentifier]) {
		return NO;
	}
	else {
		return YES;
	}
}

- (void)updateWithResponse:(MPCPlayerResponse *)response {
	self.songs = [response.tracklist.items copy];

	NSIndexPath *identifierPath = [
		NSIndexPath
		indexPathForRow: response.tracklist.playingItem.indexPath.row + 1
		inSection: 0
	];
	MPCPlayerResponseItem *identifierSong = [response.tracklist.items itemAtIndexPath: identifierPath];
	self.queueIdentifier = identifierSong.contentItemIdentifier;
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Subtracted by one because the tracklist contains the playing item.
	return [self.songs numberOfItemsInSection:0] - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EMQueueSongCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"EMQueueSongCell"];
	}

	NSIndexPath *modelSongPath = [NSIndexPath indexPathForRow: indexPath.row + 1 inSection: 0];
	MPModelSong *modelSong = [self.songs itemAtIndexPath:modelSongPath].metadataObject.song;
	MPMediaItem *song = [MPMediaItem itemFromSong:modelSong];
	
	cell.textLabel.text = song.title;
	cell.detailTextLabel.text = song.artist;

	UIImage *artwork = [song.artwork imageWithSize:song.artwork.bounds.size];
	HBLogDebug(@"%@", artwork);
	if (artwork) {
		cell.imageView.image = artwork;
	}
	else {
		MPArtworkCatalog *catalog = [song artworkCatalog];
		HBLogDebug(@"requesting image");
		[catalog requestImageWithCompletionHandler:^void (UIImage *image) {
			HBLogDebug(@"%@", image);
			if (image) {
				HBLogDebug(@"Updating Image!");
				dispatch_async(dispatch_get_main_queue(), ^{
					UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:indexPath];
					if (oldCell) {
						oldCell.imageView.image = image;
					}
				});
			}
		}];
	}

	return cell;
}
@end