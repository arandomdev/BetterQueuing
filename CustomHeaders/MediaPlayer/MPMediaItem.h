#import <MediaPlayer/MPMediaItem.h>

#import "MPArtworkCatalog.h"

@interface MPMediaItem ()
+ (MPMediaItem *)itemFromSong:(id)item;
- (MPArtworkCatalog *)artworkCatalog;
@end