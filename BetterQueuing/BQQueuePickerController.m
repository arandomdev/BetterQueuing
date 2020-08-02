#import "BQQueuePickerController.h"

@implementation BQQueuePickerController
- (instancetype)initWithController:(MPRequestResponseController *)controller dismissHandler:(void (^)(NSArray<NSDictionary<NSString *, id> *> *))handler {
	[controller beginAutomaticResponseLoading];
	self = [super initWithCollection:controller.response.tracklist.items dismissHandler:handler];
	if (self) {
		self.responseController = controller;
		self.playerController = [[BQPlayerController alloc] initWithRequestController:controller];

		// listen for changes in the queue
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_responseChanged:) name:@"BQResponseReplacedNotification" object:nil];

		// Skip the current song in the queue
		self.dataSource.collectionOffset = 1;

		// add a shuffle button to the queue
		UIBarButtonItem *shuffleButton = [[UIBarButtonItem alloc] initWithTitle:@"Shuffle" style:UIBarButtonItemStylePlain target:self action:@selector(_shuffleQueue)];
		self.navigationBar.topItem.rightBarButtonItems = [self.navigationBar.topItem.rightBarButtonItems arrayByAddingObject:shuffleButton];

		return self;
	}
	else {
		[controller endAutomaticResponseLoading];
		return nil;
	}
}

- (void)_shuffleQueue {
	[self.playerController shuffleQueue];
}

- (void)_responseChanged:(NSNotification *)note {
	MPSectionedCollection *newCollection = self.responseController.response.tracklist.items;
	if ([self.dataSource shouldUpdateWithCollection:newCollection]) {
		[self.dataSource updateWithCollection:newCollection];

		[self.tableView reloadData];
		if ([self.tableView numberOfRowsInSection:0] != 0) {
			NSIndexPath *zeroIndex = [NSIndexPath indexPathForRow: 0 inSection: 0];
			[self.tableView scrollToRowAtIndexPath:zeroIndex atScrollPosition: UITableViewScrollPositionTop animated: YES];
		}
	}
}

- (void)_dismissPicker {
	[super _dismissPicker];

	[self.responseController endAutomaticResponseLoading];
	[NSNotificationCenter.defaultCenter removeObserver:self name:@"BQResponseReplacedNotification" object:nil];
}
@end