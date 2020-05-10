#import "EMQueueViewController.h"

@implementation EMQueueViewController
- (instancetype)initWithRequestController:(MPRequestResponseController *)requestController {
	self = [super init];
	if (self) {
		// set up the player controller
		[requestController beginAutomaticResponseLoading];
		self.requestController = requestController;

		self.playerController = [[EMPlayerController alloc] initWithRequestController:requestController];

		// create the tableView
		UITableViewController *tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
		self.tableView = tableViewController.tableView;

		self.dataSource = [[EMQueueDataSource alloc] initWithResponse:requestController.response];
		self.tableView.dataSource = self.dataSource;
		self.tableView.allowsMultipleSelection = YES;

		// listen to response changes to react to changes in the queue
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(responseChanged:) name:@"EMResponseReplacedNotification" object:nil];

		// define the navigation view
		self.modalPresentationStyle = UIModalPresentationFullScreen;
		[self setViewControllers:@[tableViewController] animated:NO];

		UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopButtonPressed)];
		self.navigationBar.topItem.leftBarButtonItem = stopButton;

		UIBarButtonItem *shuffleButton = [[UIBarButtonItem alloc] initWithTitle:@"Shuffle" style:UIBarButtonItemStylePlain target:self action:@selector(shuffleButtonPressed)];
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed)];
		self.navigationBar.topItem.rightBarButtonItems = @[doneButton, shuffleButton];
	}
	return self;
}

- (void)dismissPicker {
	[self.requestController endAutomaticResponseLoading];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)responseChanged:(NSNotification *)note {
	if ([self.dataSource shouldUpdateWithResponse:self.requestController.response]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.dataSource updateWithResponse:self.requestController.response];
			[self.tableView reloadData];

			if ([self.tableView numberOfRowsInSection:0] != 0) {
				NSIndexPath *zeroIndex = [NSIndexPath indexPathForRow: 0 inSection: 0];
				[self.tableView scrollToRowAtIndexPath:zeroIndex atScrollPosition: UITableViewScrollPositionTop animated: YES];
			}
		});
	}
}

#pragma mark UIBarButtonItem Actions
- (void)stopButtonPressed {
	[self dismissPicker];
}

- (void)shuffleButtonPressed {
	[self.playerController shuffleQueue];
}

- (void)doneButtonPressed {
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self dismissPicker];
	});
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Sort the index paths so that the songs get moved correctly.
		NSArray *selectedPaths = [self.tableView.indexPathsForSelectedRows sortedArrayUsingComparator: ^(NSIndexPath *path1, NSIndexPath *path2) {
			if (path1.row > path2.row) {
				return (NSComparisonResult)NSOrderedDescending;
			}
		
			if (path1.row < path2.row) {
				return (NSComparisonResult)NSOrderedAscending;
			}
			return (NSComparisonResult)NSOrderedSame;
		}];

		bool allSuccessful = YES;
		int targetIndex = 0;
		for (NSIndexPath *indexPath in selectedPaths) {
			if (![self.playerController moveItemAtIndex:indexPath.row toIndex:targetIndex]) {
				allSuccessful = NO;
			}
			targetIndex++;
		}

		dispatch_async(dispatch_get_main_queue(), ^(void) {
			UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
			if (allSuccessful) {
				[generator notificationOccurred: UINotificationFeedbackTypeSuccess];
			}
			else {
				[generator notificationOccurred: UINotificationFeedbackTypeError];
			}
		});
	});
}
@end