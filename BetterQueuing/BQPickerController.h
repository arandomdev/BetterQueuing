#import "BQPickerDataSource.h"

#import "../CustomHeaders/MediaPlayer/MediaPlayer.h"

@interface BQPickerController : UINavigationController
@property (nonatomic, copy) void (^dismissHandler)(NSArray<NSDictionary<NSString *, id> *> *);
@property (nonatomic, retain) BQSongProvider *songs;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) BQPickerDataSource *dataSource;

- (instancetype)initWithCollection:(MPSectionedCollection *)collection dismissHandler:(void (^)(NSArray<NSDictionary<NSString *, id> *> *))handler;

- (void)_dismissPicker;
- (void)_stopButtonPressed;
- (void)_doneButtonPressed;
@end