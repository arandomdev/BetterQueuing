#import "../CustomHeaders/MediaPlayer/MPRequestResponseController.h"

@interface EMPlayerController : NSObject {
	NSCondition *continueLock;
	bool shouldContinue;
}

@property(nonatomic, retain) MPRequestResponseController *controller;

- (instancetype)initWithRequestController:(MPRequestResponseController *)controller;

- (void)moveItemAtIndex:(NSInteger)itemIndex toIndex:(NSInteger)targetIndex;
- (void)shuffleQueue;
- (void)stopAtIndex:(NSInteger)index;

- (void)responseChanged:(NSNotification *)note;

#pragma mark override
- (void)dealloc;
@end