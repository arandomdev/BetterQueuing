#import "../CustomHeaders/MediaPlayer/MPSectionedCollection.h"
#import "../CustomHeaders/MediaPlayer/MPModelSong.h"

@interface BQSongProvider : NSObject
@property (nonatomic, retain) MPSectionedCollection *songCollection;

- (instancetype)initWithSongs:(MPSectionedCollection *)songs;
- (NSArray<MPModelSong *> *)allSongs;
- (MPModelSong *)songAtIndex:(NSInteger)index;
@end