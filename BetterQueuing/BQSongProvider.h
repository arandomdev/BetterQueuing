#import "../CustomHeaders/MediaPlayer/MediaPlayer.h"

@interface BQSongProvider : NSObject
@property (nonatomic, retain) MPSectionedCollection *songCollection;

- (instancetype)initWithSongs:(MPSectionedCollection *)songs;
- (NSArray<MPModelSong *> *)allSongs;
- (MPModelSong *)songAtIndex:(NSInteger)index;
@end