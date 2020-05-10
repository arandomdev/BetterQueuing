#import "../MediaPlaybackCore/MPCPlayerResponse.h"

@interface MPRequestResponseController : NSObject
@property (nonatomic, retain) MPCPlayerResponse *response;
- (void)reloadIfNeeded;
- (void)setNeedsReload;
- (void)beginAutomaticResponseLoading;
- (void)endAutomaticResponseLoading;
@end