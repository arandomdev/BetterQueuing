#import "BQPickerController.h"
#import "BQPlayerController.h"

#import "../CustomHeaders/MediaPlayer/MediaPlayer.h"

@interface BQQueuePickerController : BQPickerController
@property (nonatomic, retain) MPRequestResponseController *responseController;
@property (nonatomic, retain) BQPlayerController *playerController;

- (instancetype)initWithController:(MPRequestResponseController *)controller dismissHandler:(void (^)(NSArray<NSDictionary<NSString *, id> *> *))handler;

- (void)_shuffleQueue;
- (void)_responseChanged:(NSNotification *)note;

- (void)_dismissPicker;
@end