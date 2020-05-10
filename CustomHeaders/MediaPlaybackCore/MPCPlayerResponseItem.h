#import "../MediaPlayer/MPModelGenericObject.h"

@interface MPCPlayerResponseItem
@property (nonatomic,readonly) MPModelGenericObject *metadataObject;
@property (nonatomic,readonly) NSIndexPath *indexPath;
@property (nonatomic,readonly) NSString *contentItemIdentifier;
@end