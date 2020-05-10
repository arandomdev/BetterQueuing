#import "../MediaPlaybackCore/MPCPlayerResponseItem.h"

@interface MPSectionedCollection : NSObject <NSCopying>
-(long long)numberOfItemsInSection:(long long)section;
-(MPCPlayerResponseItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
@end