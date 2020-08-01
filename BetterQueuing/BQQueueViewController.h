#import "BQPickerDataSource.h"
#import "BQPlayerController.h"

#import "../CustomHeaders/MediaPlayer/MPRequestResponseController.h"

@interface BQQueueViewController : UINavigationController

@property (nonatomic, retain) MPRequestResponseController *requestController;
@property (nonatomic, retain) BQPlayerController *playerController;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) BQPickerDataSource *dataSource;

- (instancetype)initWithRequestController:(MPRequestResponseController *)requestController;

- (void)dismissPicker;
- (void)responseChanged:(NSNotification *)note;

#pragma mark UIBarButtonItem Actions
- (void)stopButtonPressed;
- (void)shuffleButtonPressed;
- (void)doneButtonPressed;
@end