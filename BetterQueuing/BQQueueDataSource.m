#import "BQQueueDataSource.h"

#import "../CustomHeaders/MediaPlaybackCore/MPCPlayerResponseItem.h"

#import "../CustomHeaders/MediaPlayer/MPMediaItem.h"
#import "../CustomHeaders/MediaPlayer/MPConcreteMediaItemArtwork.h"

// TODO: re-code with header

@implementation BQQueueDataSource
- (instancetype)initWithCollection:(MPSectionedCollection *)collection {
	self = [super init];
	if (self) {
		self.songs = [[BQSongProvider alloc] initWithSongs:collection];
	}
	return self;
}

/*
	The data source should update it's data only when the items in the
	queue changes. To do this, we can compare all the items in the
	given collection to the items we have currently, using the
	persistentID as a key. 
*/
- (bool)shouldUpdateWithCollection:(MPSectionedCollection *)collection {
	BOOL isDifferent = NO;
	NSArray<MPModelSong *> *newSongs = [[[BQSongProvider alloc] initWithSongs:collection] allSongs];
	NSArray<MPModelSong *> *currentSongs = [self.songs allSongs];

	if (newSongs.count != currentSongs.count) {
		isDifferent = YES;
	}
	else {
		for (int i = 0; i < newSongs.count; i++) {
			if (newSongs[i].identifiers.persistentID != currentSongs[i].identifiers.persistentID) {
				isDifferent = YES;
				break;
			}
		}
	}

	return isDifferent;
}

- (void)updateWithCollection:(MPSectionedCollection *)collection {
	self.songs = [[BQSongProvider alloc] initWithSongs:collection];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Subtracted by one because the collection contains the playing item.
	return self.songs.songCollection.totalItemCount - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BQQueueSongCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"BQQueueSongCell"];
	}

	// to account for the now playing item
	NSInteger realIndex = indexPath.row + 1;
	MPModelSong *modelSong = [self.songs songAtIndex:realIndex];
	MPMediaItem *song = [MPMediaItem itemFromSong:modelSong];
	
	cell.textLabel.text = song.title;
	cell.detailTextLabel.text = song.artist;

	cell.imageView.image = [UIImage imageNamed: @"MissingArtworkMusicNote144"];
	MPArtworkCatalog *catalog = [(MPConcreteMediaItemArtwork *)song.artwork artworkCatalog];
	[catalog requestImageWithCompletionHandler:^void (UIImage *image) {
		if (image) {

			dispatch_async(dispatch_get_main_queue(), ^{
				UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:indexPath];
				if (oldCell) {
					oldCell.imageView.image = image;
					[oldCell setNeedsLayout];
				}
			});
		}
	}];

	return cell;
}
@end