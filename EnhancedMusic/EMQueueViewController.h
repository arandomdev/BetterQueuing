#import "EMQueueDataSource.h"
#import "EMPlayerController.h"

#import "../CustomHeaders/MediaPlayer/MPRequestResponseController.h"

@interface EMQueueViewController : UINavigationController

@property (nonatomic, retain) MPRequestResponseController *requestController;
@property (nonatomic, retain) EMPlayerController *playerController;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) EMQueueDataSource *dataSource;

- (instancetype)initWithRequestController:(MPRequestResponseController *)requestController;

- (void)dismissPicker;
- (void)responseChanged:(NSNotification *)note;

#pragma mark UIBarButtonItem Actions
- (void)stopButtonPressed;
- (void)shuffleButtonPressed;
- (void)doneButtonPressed;
@end