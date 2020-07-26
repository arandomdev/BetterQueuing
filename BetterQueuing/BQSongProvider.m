#import "BQSongProvider.h"

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
		NSMutableArray *converted = [NSMutableArray arrayWithCapacity: allSongs.count];
		for (int i = 0; i < allSongs.count; i++) {
			converted[i] = ((NSArray<MPCPlayerResponseItem *> *)allSongs)[i].metadataObject.song;
		}
		return [converted copy];
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
	else {
		[NSException raise:@"UnknownClass" format:@"Collection contains an unknown class: %@", song];
		return nil;
	}
}
@end