#import "../CustomHeaders/MediaPlayer/MPSectonedCollection.h"
#import "../CustomHeaders/MediaPlayer/MPModelSong.h"

@interface BQSongProvider : NSObject
@property (nonatomic, retain) MPSectonedCollection *songs;

- (instancetype)initWithSongs:(MPSectonedCollection *)songs;
- (NSArray<MPModelSong *> *)allItems;
- (MPModelSong *)songAtIndexPath:(NSIndexPath *)indexPath;
@end