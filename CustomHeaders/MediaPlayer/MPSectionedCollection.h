#import "../MediaPlaybackCore/MPCPlayerResponseItem.h"

@interface MPSectionedCollection : NSObject <NSCopying>
-(long long)numberOfSections;
-(long long)numberOfItemsInSection:(long long)section;
-(id)itemAtIndexPath:(NSIndexPath *)indexPath;
-(NSArray *)allItems;
@end