#import "MPCPlayerResponseTracklist.h"

@interface MPCPlayerResponse
@property (nonatomic,readonly) MPCPlayerResponseTracklist *tracklist;

#pragma mark MPCPlayerResponse
@property (getter=isValid, nonatomic, readonly) bool valid;
@end