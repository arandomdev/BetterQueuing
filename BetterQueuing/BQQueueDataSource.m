#import "BQQueueDataSource.h"

#import "../CustomHeaders/MediaPlaybackCore/MPCPlayerResponseItem.h"

#import "../CustomHeaders/MediaPlayer/MPMediaItem.h"
#import "../CustomHeaders/MediaPlayer/MPConcreteMediaItemArtwork.h"

// TODO: re-code with header

@implementation EMQueueDataSource
- (instancetype)initWithCollection:(MPSectionedCollection *)collection {
	self = [super init];
	if (self) {
		[self updateWithResponse:response];
	}
	return self;
}

/*
	The data source should update it's data only when the items in the
	queue changes. To do this, we can compare all the items in the
	given response to the items we have currently, using the
	persistantID as a key. 
*/
- (bool)shouldUpdateWithCollection:(MPSectionedCollection *)collection {
	BOOL isDifferent = NO;
	NSArray<MPCPlayerResponseItem *> *givenItems = [collection allItems];
	NSArray<MPCPlayerResponseItem *> *targetItems = [self.songs allItems];
	if (givenItems.count != targetItems.count) {
		isDifferent = YES;
	}
	else {
		for (int i = 0; i < givenItems.count; i++) {
			if (givenItems[i].metadataObject.identifiers.persistentID != targetItems[i].metadataObject.identifiers.persistentID) {
				isDifferent = YES;
				break;
			}
		}
	}

	return isDifferent;
}

- (void)updateWithCollection:(MPSectionedCollection *)collection {
	self.songs = [collection copy];

	NSInteger identifierIndex = response.tracklist.playingItem.indexPath.row + 1;
	if (
		[self.songs numberOfSections] < 1
		|| [self.songs numberOfItemsInSection: 0] <= identifierIndex
	) {
		self.queueIdentifier = @"";
	}

	else {
		NSIndexPath *identifierPath = [
			NSIndexPath
			indexPathForRow: identifierIndex
			inSection: 0
		];
		MPCPlayerResponseItem *identifierSong = [response.tracklist.items itemAtIndexPath: identifierPath];
		self.queueIdentifier = identifierSong.contentItemIdentifier;
	}
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