#import "BQPickerController.h"
#import "NSArray+Mappable.h"

@implementation BQPickerController
- (instancetype)initWithCollection:(MPSectionedCollection *)collection dismissHandler:(void (^)(NSArray<NSDictionary<NSString *, id> *> *))handler {
	self = [super init];
	if (self) {
		self.dismissHandler = handler;
		self.songs = [[BQSongProvider alloc] initWithSongs:collection];

		// create and add the table view
		UITableViewController *tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
		UITableView *tableView = tableViewController.tableView;
		tableView.allowsMultipleSelection = YES;

		BQPickerDataSource *dataSource = [[BQPickerDataSource alloc] initWithCollection:collection collectionOffset:0];
		tableView.dataSource = dataSource;

		[self setViewControllers:@[tableViewController] animated:NO];

		self.tableView = tableView;
		self.dataSource = dataSource;

		// add the navigation controls
		self.modalPresentationStyle = UIModalPresentationFullScreen;

		UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(_stopButtonPressed)];
		self.navigationBar.topItem.leftBarButtonItem = stopButton;

		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(_doneButtonPressed)];
		self.navigationBar.topItem.rightBarButtonItem = doneButton;
	}
	return self;
}

- (void)_dismissPicker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_stopButtonPressed {
	[self _dismissPicker];
}

- (void)_doneButtonPressed {
	if (!self.dismissHandler) {
		return;
	}

	// sort the index paths
	NSArray *selectedPaths = [self.tableView.indexPathsForSelectedRows sortedArrayUsingComparator: ^(NSIndexPath *path1, NSIndexPath *path2) {
		if (path1.row > path2.row) {
			return (NSComparisonResult)NSOrderedDescending;
		}
	
		if (path1.row < path2.row) {
			return (NSComparisonResult)NSOrderedAscending;
		}
		return (NSComparisonResult)NSOrderedSame;
	}];

	NSArray *entries = [selectedPaths mapObjectsUsingBlock:^NSDictionary * (NSIndexPath *path, NSUInteger index) {
		NSNumber *selectedIndex = @(path.row);
		MPMediaItem *item = [MPMediaItem itemFromSong:[self.songs songAtIndex:path.row]];

		return @{
			@"index" : selectedIndex,
			@"item" : item
		};
	}];

	self.dismissHandler(entries);
	[self _dismissPicker];
}
@end