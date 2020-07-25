#import "BQSongProvider.h"

@implementation BQSongProvider
- (instancetype)initWithSongs:(MPSectonedCollection *)songs {
	self = [super init];
	if (self) {
		self.songs = songs;
	}
	return self;
}

- (NSArray<MPModelSong *> *)allItems;

- (MPModelSong *)songAtIndexPath:(NSIndexPath *)indexPath {
	id song = [self.songs itemAtIndexPath:indexPath];
	
	if ([song isKindOfClass:[MPModelSong class]]) {
		return song;
	}
	else {
		return ((MPCPlayerResponseItem *)song).metadataObject;
	}
}
@end