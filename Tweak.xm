#import "CustomHeaders/UIContextMenuConfiguration.h"
#import "CustomHeaders/MediaPlaybackCore/MediaPlaybackCore.h"

#import "BetterQueuing/BQQueueViewController.h"
#import "BetterQueuing/BQPlayerController.h"


BOOL CustomQueueCountEnabled = NO;
NSInteger CustomQueueCount = 99;

NSInteger AlwaysClearMode = 2;

BOOL HideControlsEnabled = NO;

BOOL BetterTabShortcutEnabled = NO;


typedef struct {
	long long reverseCount;
	long long forwardCount;
} TracklistRange;

@interface UIAlertAction ()
@property (nonatomic,copy) void (^handler)(UIAlertAction *action);
@end

@interface NowPlayingQueueViewController
- (id)collectionView:(id)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point;
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint *)targetContentOffset;
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView;
@end


// Custom Queue Count
%hook MPCPlayerRequest
-(TracklistRange)tracklistRange {
	TracklistRange range = %orig();

	if (CustomQueueCountEnabled && range.forwardCount > 90) {
		range.forwardCount = CustomQueueCount;
	}

	return range;
}
%end


// Always Clear
%hook TabBarController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
	if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {

		UIAlertController *alertController = (UIAlertController *)viewControllerToPresent;
		if (
			[alertController.message containsString:@"playing"]
			&& [alertController.message containsString:@"queue"]
		) {
			if (AlwaysClearMode != 2) {
				UIAlertAction *clearAction = alertController.actions[AlwaysClearMode];
				clearAction.handler(clearAction);
				
				if (completion) {
					completion();
				}
				return;
			}
		}
	}

	%orig;
}
%end


%hook NowPlayingViewController
- (void)controller:(id)controller defersResponseReplacement:(void (^)())origBlock {
	/*
		This method is called by MPRequestResponseController whenever the response
		is changed. I assume that the original block is called when the 
		NowPlayingViewController wants the change to happen.
	*/
	void (^injectedBlock)() = ^void() {
		origBlock();

		[NSNotificationCenter.defaultCenter postNotificationName:@"EMResponseReplacedNotification" object:self];
	};
	%orig(controller, injectedBlock);
}
%end

%hook NowPlayingQueueViewController
// Up Next Menu Actions
- (id)collectionView:(id)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
	/*
		This is method is called when ever a song cell is long pressed.
		Originally, this returns a configuration with an action provider
		that provides a UIMenu consisting of a UIContextMenuInteractionDeferred
		menu.

		The original actionProvider uses this loading action while it asynchronously
		fetches information about the song. When it finishes fetching the information,
		it calls the private method _updateVisibleMenuWithBlock: on it's
		UIContextMenuInteraction instance.

		Adding a UIMenu happens in two parts, first add the custom menu to the children
		of the UIContextMenuInteractionDeferred menu, secondly re-add the menu when
		the original action provider updates the menu (see doc for
		_updateVisibleMenuWithBlock hook).

		Hierarchy
		<UIMenu; identifier = com.apple.menu.dynamic.<generated uuid>; children = [
			<UIMenu; identifier = com.apple.menu.UIContextMenuInteractionDeferred; children = [
				<UIAction; identifier = com.apple.UIAction.UIContextMenuInteractionLoading;>,
				<UIMenu; identifier = com.haotestlabs.StickyMenu.1; children = [...];>
			];>
		];>

	*/

	// Only show for items that are in the queue, not for ones in the history queue.
	if (indexPath.section == 0) {
		return %orig;
	}

	UIContextMenuConfiguration *contextConfig = %orig;
	UIMenu *(^origActionProvider)(NSArray *) = contextConfig.actionProvider;

	UIMenu *(^newActionProvider)(NSArray *) = ^UIMenu *(NSArray *suggestedActions) {
		UIMenu *origMenu = origActionProvider(suggestedActions);

		UIViewController *nowPlayingController = ((UIViewController *)self).parentViewController;
		MPRequestResponseController *requestController = MSHookIvar<MPRequestResponseController *>(nowPlayingController, "playerRequestController");

		// This action will move the long pressed item to the top of the playing queue.
		UIAction *playNextAction = [UIAction actionWithTitle:@"Play Next" image:[UIImage systemImageNamed:@"text.insert"] identifier:nil handler:^void (UIAction *sender) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				EMPlayerController *controller = [[EMPlayerController alloc] initWithRequestController:requestController];
				bool successful = [controller moveItemAtIndex: indexPath.row toIndex: 0];

				dispatch_async(dispatch_get_main_queue(), ^{
					UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
					if (successful) {
						[generator notificationOccurred: UINotificationFeedbackTypeSuccess];
					}
					else {
						[generator notificationOccurred: UINotificationFeedbackTypeError];
					}
				});
			});
		}];

		UIAction *stopHereAction = [UIAction actionWithTitle:@"Stop Here" image:[UIImage systemImageNamed:@"arrow.down.to.line"] identifier:nil handler:^void (UIAction *sender) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				EMPlayerController *controller = [[EMPlayerController alloc] initWithRequestController:requestController];
				[controller stopAtIndex:indexPath.row];
			});
		}];

		// This action will display the song picker
		UIAction *queueSongsAction = [UIAction actionWithTitle:@"Queue Songs" image:[UIImage systemImageNamed:@"list.dash"] identifier:nil handler:^void (UIAction *sender) {
			EMQueueViewController *picker = [[EMQueueViewController alloc] initWithRequestController:requestController];
			[nowPlayingController presentViewController:picker animated:YES completion:nil];
		}];
		UIMenu *customMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"com.haotestlabs.StickyMenu" options:UIMenuOptionsDisplayInline children:@[playNextAction, stopHereAction, queueSongsAction]];

		UIMenu *deferredMenu = (UIMenu*)origMenu.children[0];
		deferredMenu = [deferredMenu menuByReplacingChildren:[deferredMenu.children arrayByAddingObject:customMenu]];
		UIMenu *newMenu = [origMenu menuByReplacingChildren:@[deferredMenu]];

		return newMenu;
	};
	contextConfig.actionProvider = newActionProvider;

	return contextConfig;
}

// Hide Controls
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint *)targetContentOffset {
	if (!HideControlsEnabled) {
		%orig();
		return;
	}

	/*
		velocity:
			positive -> scroll down
			negative -> scroll up
	*/

	if ([scrollView isKindOfClass:[UICollectionView class]]) {
		UICollectionView *collectionView = (UICollectionView *)scrollView;
		NSSet *visibleSections = [NSSet setWithArray:[collectionView.indexPathsForVisibleItems valueForKey:@"section"]];

		/*
			Hide the controls if the user is in the history section and scrolls down.
			Hide the controls if the user is in the playing next section and scrolls up.
		*/
		if (([visibleSections containsObject:@0] && velocity.y > 0) || ([visibleSections containsObject:@1] && velocity.y < 0)) {
			velocity.y = -1 * velocity.y;
			%orig(scrollView, velocity, targetContentOffset);
			return;
		}
	}

	%orig();
}

// Better Tab Shortcut
%new
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if (BetterTabShortcutEnabled && [scrollView isKindOfClass:[UICollectionView class]]) {
		UICollectionView *collectionView = (UICollectionView *)scrollView;

		NSSet *visibleSections = [NSSet setWithArray:[collectionView.indexPathsForVisibleItems valueForKey:@"section"]];
		
		CGPoint temp = CGPointMake(0, 0);
		if ([visibleSections containsObject:@0]) {
			// Hide the controls
			[self scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(0, 1) targetContentOffset:&temp];
			return YES;
		}
		else {
			// Show the controls
			[self scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(0, -1) targetContentOffset:&temp];

			NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:1];
			[collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
			return NO;
		}
	}
	return YES;
}
%end

%hook UIContextMenuInteraction
- (void)_updateVisibleMenuWithBlock:(UIMenu *(^)(UIMenu *oldMenu))originalBlock {
	/*
		The original block is called for every secondary UIMenu, i.e. 
		UIContextMenuInteractionDeferred. In the second stop of adding
		a menu, we find any UIMenus with the identifier
		com.haotestlabs.StickyMenu and re-add them to the new menu
		provided by the original block.

		Hierarchy before
		<UIMenu; identifier = com.apple.menu.dynamic.<generated uuid>; children = [
			<UIMenu; identifier = com.apple.menu.UIContextMenuInteractionDeferred; children = [
				<UIAction; identifier = com.apple.UIAction.UIContextMenuInteractionLoading;>,
				<UIMenu; identifier = com.haotestlabs.StickyMenu; children = [...];>
			];>
		];>

		Hierarchy after
		<UIMenu; identifier = com.apple.menu.dynamic.<generated uuid>; children = [
			<UIMenu; identifier = com.apple.menu.dynamic.<generated uuid>; children = [...];>,
			<UIMenu; identifier = com.haotestlabs.StickyMenu; children = [...];>,
			<UIMenu; identifier = com.apple.menu.dynamic.<generated uuid>; children = [...];>
		];>
	*/
	UIMenu *(^newBlock)(UIMenu *oldMenu) = ^UIMenu *(UIMenu *oldMenu) {
		NSMutableArray<UIMenu *> *stickyMenus = [NSMutableArray new];
		for (UIMenu *menu in oldMenu.children) {
			if ([menu.identifier isEqual:@"com.haotestlabs.StickyMenu"]) {
				[stickyMenus addObject:menu];
			}
		}

		UIMenu *newMenu = originalBlock(oldMenu);
		NSMutableArray *children = [newMenu.children mutableCopy];
		for (UIMenu *menu in stickyMenus) {
			[children insertObject:menu atIndex:1];
		}

		newMenu = [newMenu menuByReplacingChildren:[children copy]];
		return newMenu;
	};
	%orig(newBlock);
}
%end


static void ReloadPreferences() {
	NSString *preferencesFilePath = [NSString stringWithFormat:@"/User/Library/Preferences/com.haotestlabs.betterqueuingpreferences.plist"];
	
	NSData *fileData = [NSData dataWithContentsOfFile:preferencesFilePath];
	if (fileData) {
		NSError *error = nil;
		NSDictionary *preferences = [NSPropertyListSerialization propertyListWithData:fileData options:NSPropertyListImmutable format:nil error:&error];
		
		if (error) {
			HBLogError(@"Unable to read preference file, Error: %@", error);
		}
		else {
			if (preferences[@"AlwaysClearMode"]) {
				AlwaysClearMode = [preferences[@"AlwaysClearMode"] integerValue];
			}
			if (preferences[@"CustomQueueCountEnabled"]) {
				CustomQueueCountEnabled = [preferences[@"CustomQueueCountEnabled"] boolValue];
			}
			if (preferences[@"CustomQueueCount"]) {
				CustomQueueCount = [preferences[@"CustomQueueCount"] integerValue];
			}
			if (preferences[@"HideControlsEnabled"]) {
				HideControlsEnabled = [preferences[@"HideControlsEnabled"] boolValue];
			}
			if (preferences[@"BetterTabShortcutEnabled"]) {
				BetterTabShortcutEnabled = [preferences[@"BetterTabShortcutEnabled"] boolValue];
			}
			// TODO: remove
			// if (preferences[@""]) {
			// 	 = [preferences[@""] intValue];
			// }
		}
	}
}

%ctor {
	HBLogDebug(@"Hooked"); // TODO: remove
	
	%init(NowPlayingViewController=objc_getClass("MusicApplication.NowPlayingViewController"),
		NowPlayingQueueViewController=objc_getClass("MusicApplication.NowPlayingQueueViewController"),
		TabBarController=objc_getClass("MusicApplication.TabBarController")
	);

	ReloadPreferences();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)ReloadPreferences,
		CFSTR("com.haotestlabs.betterqueuingpreferences.reload"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);

	// TODO: remove
	// [NSNotificationCenter.defaultCenter addObserverForName:nil object:nil queue:nil usingBlock:^void (NSNotification *note) {
	// 	HBLogDebug(@"%@, %@", note.name, note.object);
	// }];
}