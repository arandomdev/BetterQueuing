#import "BQSongProvider.h"
#import "NSArray+Mappable.h"

@implementation BQSongProvider
- (instancetype)initWithSongs:(MPSectionedCollection *)songs {
	self = [super init];
	if (self) {
		self.songCollection = songs;
	}
	return self;
}

- (NSArray<MPModelSong *> *)allSongs {
	NSArray *allSongs = [self.songCollection allItems];
	if (allSongs.count == 0) {
		return allSongs;
	}
	else if ([allSongs[0] isKindOfClass:[MPModelSong class]]) {
		return allSongs;
	}
	else if ([allSongs[0] isKindOfClass:[MPCPlayerResponseItem class]]) {
		return [allSongs mapObjectsUsingBlock:^MPModelSong *(MPCPlayerResponseItem *item, NSUInteger index) {
			return item.metadataObject.song;
		}];
	}
	else if ([allSongs[0] isKindOfClass:[MPModelPlaylistEntry class]]) {
		return [allSongs mapObjectsUsingBlock:^MPModelSong *(MPModelPlaylistEntry *entry, NSUInteger index) {
			return entry.song;
		}];
	}
	else {
		[NSException raise:@"UnknownClass" format:@"Collection contains an unknown class: %@", allSongs[0]];
		return nil;
	}
}

- (MPModelSong *)songAtIndex:(NSInteger)index {
	id song = [self.songCollection itemAtIndexPath:[self.songCollection indexPathForGlobalIndex:index]];
	
	if ([song isKindOfClass:[MPModelSong class]]) {
		return song;
	}
	else if ([song isKindOfClass:[MPCPlayerResponseItem class]]) {
		return ((MPCPlayerResponseItem *)song).metadataObject.song;
	}
	else if ([song isKindOfClass:[MPModelPlaylistEntry class]]) {
		return ((MPModelPlaylistEntry *)song).song;
	}
	else {
		[NSException raise:@"UnknownClass" format:@"Collection contains an unknown class: %@", song];
		return nil;
	}
}
@end