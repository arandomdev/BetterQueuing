#import "../MediaPlaybackCore/MPCPlayerResponseItem.h"

@interface MPSectionedCollection : NSObject <NSCopying>
@property (nonatomic,readonly) NSInteger totalItemCount;

-(long long)numberOfSections;
-(long long)numberOfItemsInSection:(NSInteger)section;
-(id)itemAtIndexPath:(NSIndexPath *)indexPath;
-(NSArray *)allItems;
-(NSIndexPath *)indexPathForGlobalIndex:(NSInteger)index ;
@end