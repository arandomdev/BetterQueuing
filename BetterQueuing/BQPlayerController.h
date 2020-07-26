#import "../CustomHeaders/MediaPlayer/MPRequestResponseController.h"

@interface BQPlayerController : NSObject {
	NSCondition *continueLock;
	bool shouldContinue;

	bool commandSuccessful;
}

@property(nonatomic, retain) MPRequestResponseController *controller;

- (instancetype)initWithRequestController:(MPRequestResponseController *)controller;

- (bool)moveItemAtIndex:(NSInteger)itemIndex toIndex:(NSInteger)targetIndex;
- (void)shuffleQueue;
- (void)stopAtIndex:(NSInteger)index;

- (void)responseChanged:(NSNotification *)note;

#pragma mark override
- (void)dealloc;
@end