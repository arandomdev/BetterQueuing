#import <MediaPlayer/MPMediaPickerController.h>
#import <HBLog.h>

#import "CustomHeaders/UIContextMenuConfiguration.h"
#import "CustomHeaders/MediaPlaybackCore/MediaPlaybackCore.h"
#import "CustomHeaders/MediaPlayer/MediaPlayer.h"

#import "BetterQueuing/BetterQueuing.h"

@import MediaPlayer;

#pragma mark Custom Queue Count
/*
	Allows the user to change how many items are shown in
	the up next queue at once.
*/

BOOL CustomQueueCountEnabled = NO;
NSInteger CustomQueueCount = 99;

typedef struct {
	long long reverseCount;
	long long forwardCount;
} TracklistRange;

%hook MPCPlayerRequest
-(TracklistRange)tracklistRange {
	TracklistRange range = %orig();

	/*
		The forwardCount comparison is there to filter
		out ranges with a 0 forwardCount. I don't know
		what they're for, but it probably isn't good to
		change them.
	*/
	if (CustomQueueCountEnabled && range.forwardCount > 90) {
		range.forwardCount = CustomQueueCount;
	}

	return range;
}
%end

#pragma mark Shared Response Controller
/*
	Provides a global MPRequestResponseController to change
	and control the queue. This controller should only be
	used to execute commands, and not to be used to enumerate
	the queue.

	SharedRequestResponseController() should be used for basic controls and
	adding items to the queue. NOT FOR QUEUE ENUMERATION.

	SharedNowPlayingResponseController() can be used for queue enumeration
	and controls. I assume that I shouldn't use it when the now playing
	view isn't present, but i haven't tested that.

*/

static id _playbackEngine;
static id _nowPlayingViewController;

%hook MPRequestResponseController
- (void)setDelegate:(id)delegate {
	if ([delegate isKindOfClass:[objc_getClass("MusicApplication.PlaybackEngineController") class]]) {
		_playbackEngine = delegate;
	}
	else if ([delegate isKindOfClass:[objc_getClass("MusicApplication.NowPlayingViewController") class]]) {
		_nowPlayingViewController = delegate;
	}
	%orig();
}
%end

MPRequestResponseController *SharedRequestResponseController() {
	if (_playbackEngine) {
		return MSHookIvar<MPRequestResponseController *>(_playbackEngine, "playerRequestResponseController");
	}
	else {
		return nil;
	}
}

MPRequestResponseController *SharedNowPlayingResponseController() {
	if (_nowPlayingViewController) {
		return MSHookIvar<MPRequestResponseController *>(_nowPlayingViewController, "playerRequestController");
	}
	else {
		return nil;
	}
}


#pragma mark Response Replacement Notification
%hook MusicApplication_NowPlayingViewController
- (void)controller:(id)controller defersResponseReplacement:(void (^)())origBlock {
	/*
		This method is called by MPRequestResponseController whenever the response
		is changed. I assume that the original block is called when the 
		NowPlayingViewController wants the change to happen.
	*/
	void (^injectedBlock)() = ^void() {
		origBlock();
		[NSNotificationCenter.defaultCenter postNotificationName:@"BQResponseReplacedNotification" object:self];
	};
	%orig(controller, injectedBlock);
}
%end

#pragma mark Always Clear
/*
	Suppresses the "do you want to keep for clear" prompt,
	and automatically chooses and option. The modes are as
	follows:

	0 = Keep
	1 = Clear
	2 = Ask
*/

NSInteger AlwaysClearMode = 2;

@interface UIAlertAction ()
@property (nonatomic,copy) void (^handler)(UIAlertAction *action);
@end

%hook MusicApplication_TabBarController
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

#pragma mark Hide Controls
/*
	Attempts to hide the transport and volume controls when
	the user scrolls in the up next queue view.
*/
BOOL HideControlsEnabled = NO;

%hook MusicApplication_NowPlayingQueueViewController
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint *)targetContentOffset {
	if (!HideControlsEnabled) {
		%orig();
		return;
	}

	/*
		velocity:
			positive -> scroll down
			negative -> scroll up (^)
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
%end

#pragma mark Better Tab Bar Shortcut
/*
	Overrides the default tab bar tap, and makes it first go to the
	top of the up next queue section, and then to the top of the
	history section.
*/

BOOL BetterTabShortcutEnabled = NO;

%hook MusicApplication_NowPlayingQueueViewController
%new
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if (BetterTabShortcutEnabled && [scrollView isKindOfClass:[UICollectionView class]]) {
		UICollectionView *collectionView = (UICollectionView *)scrollView;

		CGFloat upNextOffset = MSHookIvar<CGFloat>(self, "upNextSectionMinY");
		CGPoint temp = CGPointMake(0, 0);

		if (upNextOffset == collectionView.contentOffset.y) {
			// Hide the controls and scroll to the top.
			[self scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(0, 1) targetContentOffset:&temp];
			return YES;
		}

		// scroll to the up next header and show the controls
		[self scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(0, -1) targetContentOffset:&temp];
		CGPoint offset = CGPointMake(0, upNextOffset);
		[collectionView setContentOffset:offset animated:YES];
		return NO;
	}
	return YES;
}
%end

#pragma mark Queue Options
/*
	Adds additional actions to the context menu when a song is forced pressed.
	MusicApplication.NowPlayingQueueViewController (up next queue) has options
	to play the song next, stop the queue here, and to queue multiple songs.
	MusicApplication.ContainerDetailSongsViewController (playlist and albums)
	and MusicApplication_SongsViewController (all songs) both only have the
	option to queue up multiple songs.
*/

%hook MusicApplication_NowPlayingQueueViewController
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

	if (indexPath.section == 0) {
		return %orig;
	}

	UIContextMenuConfiguration *contextConfig = %orig;
	UIMenu *(^origActionProvider)(NSArray *) = contextConfig.actionProvider;

	UIMenu *(^newActionProvider)(NSArray *) = ^UIMenu *(NSArray *suggestedActions) {
		UIMenu *origMenu = origActionProvider(suggestedActions);
		UIViewController *nowPlayingController = ((UIViewController *)self).parentViewController;

		if (![nowPlayingController isKindOfClass:NSClassFromString(@"MusicApplication.NowPlayingViewController")]) {
			// It appears that in iOS 14, the controller with playerRequestController
			// is the second one.
			nowPlayingController = nowPlayingController.parentViewController;
		}

		MPRequestResponseController *queueResponseController = MSHookIvar<MPRequestResponseController *>(nowPlayingController, "playerRequestController");

		#pragma mark Play Next Action
		UIAction *playNextAction = [UIAction actionWithTitle:@"Play Next" image:[UIImage systemImageNamed:@"text.insert"] identifier:nil handler:^void (UIAction *sender) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:queueResponseController];
				bool successful = [controller moveQueueItemsToPlayNext:@[@(indexPath.row+1)]];

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

		#pragma mark Stop Queue Here Action
		UIAction *stopHereAction = [UIAction actionWithTitle:@"Stop Here" image:[UIImage systemImageNamed:@"arrow.down.to.line"] identifier:nil handler:^void (UIAction *sender) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:queueResponseController];
				[controller stopQueueAtIndex:indexPath.row+1];
			});
		}];

		#pragma mark Queue Songs Action
		UIAction *queueSongsAction = [UIAction actionWithTitle:@"Queue Songs" image:[UIImage systemImageNamed:@"list.dash"] identifier:nil handler:^void (UIAction *sender) {
			BQQueuePickerController *picker = [[BQQueuePickerController alloc] initWithController:queueResponseController dismissHandler:^void (NSArray<NSDictionary<NSString *, id> *> *entries) {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:queueResponseController];
					NSArray *itemIndices = [entries mapObjectsUsingBlock:^NSNumber *(NSDictionary *entry, NSUInteger index) {
						return @(((NSNumber *)entry[@"index"]).integerValue + 1);
					}];
					[controller moveQueueItemsToPlayNext:itemIndices];
				});
			}];
			[nowPlayingController presentViewController:picker animated:YES completion:nil];
		}];

		if ([origMenu.children[0] isKindOfClass:%c(UIDeferredMenuElement)]) {
			// for iOS 14 we can just create a new Menu with our items.
			UIMenu *customMenu = [UIMenu
									menuWithTitle:@""
									image:nil
									identifier:@"com.haotestlabs.betterqueuing.stickymenu"
									options:UIMenuOptionsDisplayInline
									children:[@[playNextAction, stopHereAction, queueSongsAction] arrayByAddingObjectsFromArray:origMenu.children]
								];
			return customMenu;
		}

		UIMenu *customMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"com.haotestlabs.betterqueuing.stickymenu" options:UIMenuOptionsDisplayInline children:[@[playNextAction, stopHereAction, queueSongsAction] arrayByAddingObjectsFromArray:origMenu.children]];
		UIMenu *deferredMenu = (UIMenu *)origMenu.children[0];
		deferredMenu = [deferredMenu menuByReplacingChildren:[deferredMenu.children arrayByAddingObject:customMenu]];
		UIMenu *newMenu = [origMenu menuByReplacingChildren:@[deferredMenu]];
		return newMenu;
	};

	contextConfig.actionProvider = newActionProvider;
	return contextConfig;
}
%end

%hook MusicApplication_ContainerDetailSongsViewController
- (id)collectionView:(id)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
	UIContextMenuConfiguration *contextConfig = %orig;
	UIMenu *(^origActionProvider)(NSArray *) = contextConfig.actionProvider;

	UIMenu *(^newActionProvider)(NSArray *) = ^UIMenu *(NSArray *suggestedActions) {
		UIMenu *origMenu = origActionProvider(suggestedActions);

		UIAction *queueSongsAction = [UIAction actionWithTitle:@"Queue Songs" image:[UIImage systemImageNamed:@"list.dash"] identifier:nil handler:^void (UIAction *sender) {
			MPModelResponse *modelResponse = MSHookIvar<MPModelResponse *>(self, "_modelResponse");
			BQPickerController *picker = [[BQPickerController alloc] initWithCollection:modelResponse.results dismissHandler:^void (NSArray<NSDictionary<NSString *, id> *> *entries) {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:SharedRequestResponseController()];
					NSArray *items = [entries mapObjectsUsingBlock:^MPMediaItem *(NSDictionary *entry, NSUInteger index) {
						return entry[@"item"];
					}];
					[controller playItemsNext:items];
				});

			}];

			[(UIViewController *)self presentViewController:picker animated:YES completion:nil];
		}];

		if ([origMenu.children[0] isKindOfClass:%c(UIDeferredMenuElement)]) {
			// for iOS 14 we can just create a new Menu with our items.
			UIMenu *customMenu = [UIMenu
									menuWithTitle:@""
									image:nil
									identifier:@"com.haotestlabs.betterqueuing.stickymenu"
									options:UIMenuOptionsDisplayInline
									children:[@[queueSongsAction] arrayByAddingObjectsFromArray:origMenu.children]
								];
			return customMenu;
		}

		UIMenu *customMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"com.haotestlabs.betterqueuing.stickymenu" options:UIMenuOptionsDisplayInline children:@[queueSongsAction]];
		UIMenu *deferredMenu = (UIMenu *)origMenu.children[0];
		deferredMenu = [deferredMenu menuByReplacingChildren:[deferredMenu.children arrayByAddingObject:customMenu]];
		UIMenu *newMenu = [origMenu menuByReplacingChildren:@[deferredMenu]];
		return newMenu;
	};

	contextConfig.actionProvider = newActionProvider;
	return contextConfig;
}
%end

%hook MusicApplication_SongsViewController
/*
	MPMediaPickerController is used instead of BQPickerController because I
	can't seem to find a MPModelResponse or a way to get all the songs shown
	in MusicApplication.SongsViewController.
*/

%new
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	[mediaPicker dismissViewControllerAnimated:YES completion:nil];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// For some reason there are a lot of duplicates, remove them.
		NSMutableArray *filteredItems = [NSMutableArray new];
		for (MPMediaItem *item in mediaItemCollection.items) {
			if (![filteredItems containsObject:item]) {
				[filteredItems addObject:item];
			}
		}

		BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:SharedRequestResponseController()];
		[controller playItemsNext:filteredItems];
	});
}

- (id)collectionView:(id)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
	UIContextMenuConfiguration *contextConfig = %orig;
	UIMenu *(^origActionProvider)(NSArray *) = contextConfig.actionProvider;

	UIMenu *(^newActionProvider)(NSArray *) = ^UIMenu *(NSArray *suggestedActions) {
		UIMenu *origMenu = origActionProvider(suggestedActions);

		UIAction *queueSongsAction = [UIAction actionWithTitle:@"Queue Songs" image:[UIImage systemImageNamed:@"list.dash"] identifier:nil handler:^void (UIAction *sender) {
			MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
			picker.delegate = self;
			picker.allowsPickingMultipleItems = YES;

			[(UIViewController *)self presentViewController:picker animated:YES completion:nil];
		}];

		if ([origMenu.children[0] isKindOfClass:%c(UIDeferredMenuElement)]) {
			// for iOS 14 we can just create a new Menu with our items.
			UIMenu *customMenu = [UIMenu
									menuWithTitle:@""
									image:nil
									identifier:@"com.haotestlabs.betterqueuing.stickymenu"
									options:UIMenuOptionsDisplayInline
									children:[@[queueSongsAction] arrayByAddingObjectsFromArray:origMenu.children]
								];
			return customMenu;
		}

		UIMenu *customMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"com.haotestlabs.betterqueuing.stickymenu" options:UIMenuOptionsDisplayInline children:@[queueSongsAction]];
		UIMenu *deferredMenu = (UIMenu *)origMenu.children[0];
		deferredMenu = [deferredMenu menuByReplacingChildren:[deferredMenu.children arrayByAddingObject:customMenu]];
		UIMenu *newMenu = [origMenu menuByReplacingChildren:@[deferredMenu]];
		return newMenu;
	};

	contextConfig.actionProvider = newActionProvider;
	return contextConfig;
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
			if ([menu.identifier isEqual:@"com.haotestlabs.betterqueuing.stickymenu"]) {
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

#pragma mark SwipeUpNext
/*
	Add a swipe option to the library view that plays the song next
*/

BOOL SwipeUpNextEnabled = YES;

@interface UICollectionViewTableLayout
@property (getter=_delegateActual,nonatomic,readonly) id delegateActual;
@end

@interface MusicApplication_SongCell
- (NSString *)title;
- (NSString *)artistName;
@end

@interface _UICollectionViewListLayoutSectionConfiguration
@property (nonatomic,copy) id leadingSwipeActionsConfigurationProvider;
@end

%hook UICollectionViewTableLayout
- (BOOL)swipeActionController:(id)controller mayBeginSwipeForItemAtIndexPath:(NSIndexPath *)indexPath {
	// Enable swipe actions
	if (!SwipeUpNextEnabled) {
		return %orig();
	}

	else if (
		[self.delegateActual isKindOfClass:[objc_getClass("MusicApplication.SongsViewController") class]]
		|| [self.delegateActual isKindOfClass:[objc_getClass("MusicApplication.ContainerDetailSongsViewController") class]]
	) {
		return YES;
	}

	else {
		return %orig();
	}
}

- (id)swipeActionController:(id)controller trailingSwipeConfigurationForItemAtIndexPath:(id)indexPath {
	// Suppress the unused delete action
	if (!SwipeUpNextEnabled) {
		return %orig();
	}

	else if (
		[self.delegateActual isKindOfClass:[objc_getClass("MusicApplication.SongsViewController") class]]
		|| [self.delegateActual isKindOfClass:[objc_getClass("MusicApplication.ContainerDetailSongsViewController") class]]
	) {
		return nil;
	}

	else {
		return %orig();
	}
}

- (UISwipeActionsConfiguration *)swipeActionController:(id)controller leadingSwipeConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (!SwipeUpNextEnabled) {
		return %orig();
	}
	else if ([self.delegateActual isKindOfClass:[NSClassFromString(@"MusicApplication.SongsViewController") class]]) {
		// for the library songs view
		UIContextualAction *playNextAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {

			// needs to be called from the main thread
			id songController = self.delegateActual;
			MusicApplication_SongCell *cell = (MusicApplication_SongCell *)[songController collectionView:[songController collectionView] cellForItemAtIndexPath:indexPath];
			
			NSString *title = [cell title];
			NSString *artist = [cell artistName];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				// Because I can't find a response, I need to find the song item by its name and artist.
				MPMediaQuery *query = [MPMediaQuery songsQuery];
				[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:title forProperty:@"title"]];
				[query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:artist forProperty:@"artist"]];

				BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:SharedRequestResponseController()];
				[controller playItemsNext:[query.items subarrayWithRange:NSMakeRange(0,1)]];
			});

			completionHandler(YES);
		}];
		playNextAction.backgroundColor = UIColor.systemBlueColor;
		playNextAction.image = [UIImage systemImageNamed:@"text.insert"];

		UISwipeActionsConfiguration *actionConfig = [UISwipeActionsConfiguration configurationWithActions:@[playNextAction]];
		return actionConfig;
	}
	else if ([self.delegateActual isKindOfClass:[NSClassFromString(@"MusicApplication.ContainerDetailSongsViewController") class]]) {
		// for playlists and albums
		UIContextualAction *playNextAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
			id songController = self.delegateActual;
			MPModelResponse *modelResponse = MSHookIvar<MPModelResponse *>(songController, "_modelResponse");
			MPModelSong *song = [[[BQSongProvider alloc] initWithSongs: modelResponse.results] songAtIndex:indexPath.row];
			MPMediaItem *item = [MPMediaItem itemFromSong:song];

			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:SharedRequestResponseController()];
				[controller playItemsNext:@[item]];
			});

			completionHandler(YES);
		}];
		playNextAction.backgroundColor = UIColor.systemBlueColor;
		playNextAction.image = [UIImage systemImageNamed:@"text.insert"];

		UISwipeActionsConfiguration *actionConfig = [UISwipeActionsConfiguration configurationWithActions:@[playNextAction]];
		return actionConfig;
	}
	else {
		return %orig();
	}
}
%end

%hook _UICollectionViewListLayoutSectionConfiguration
-(void)setTrailingSwipeActionsConfigurationProvider:(id)arg1 {
	%orig();

	if (!SwipeUpNextEnabled) {
		return;
	}

	// for the up next queue
	self.leadingSwipeActionsConfigurationProvider = ^UISwipeActionsConfiguration *(NSIndexPath *indexPath) {
		if (indexPath.section != 1) {
			// don't allow for the history section
			return nil;
		}

		UIContextualAction *playNextAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {

			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				BQPlayerController *controller = [[BQPlayerController alloc] initWithRequestController:SharedNowPlayingResponseController()];
				[controller moveQueueItemsToPlayNext:@[@(indexPath.row+1)]];
			});

			completionHandler(YES);
		}];
		playNextAction.backgroundColor = UIColor.systemBlueColor;
		playNextAction.image = [UIImage systemImageNamed:@"text.insert"];

		UISwipeActionsConfiguration *actionConfig = [UISwipeActionsConfiguration configurationWithActions:@[playNextAction]];
		return actionConfig;
	};
}
%end

#pragma mark Constructor and Preferences
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
			if (preferences[@"CustomQueueCountEnabled"]) {
				CustomQueueCountEnabled = [preferences[@"CustomQueueCountEnabled"] boolValue];
			}
			if (preferences[@"CustomQueueCount"]) {
				CustomQueueCount = [preferences[@"CustomQueueCount"] integerValue];
			}
			if (preferences[@"AlwaysClearMode"]) {
				AlwaysClearMode = [preferences[@"AlwaysClearMode"] integerValue];
			}
			if (preferences[@"HideControlsEnabled"]) {
				HideControlsEnabled = [preferences[@"HideControlsEnabled"] boolValue];
			}
			if (preferences[@"BetterTabShortcutEnabled"]) {
				BetterTabShortcutEnabled = [preferences[@"BetterTabShortcutEnabled"] boolValue];
			}
			if (preferences[@"SwipeUpNextEnabled"]) {
				SwipeUpNextEnabled = [preferences[@"SwipeUpNextEnabled"] boolValue];
			}
		}
	}
}

/*
	The hooks are initialized in "UIApplicationMain" instead of the ctor, because some classes
	like MusicApplication.ContainerDetailSongsViewController are not available to "objc_getClass"
	during the ctor.
*/
%group AppHook
%hookf (int, UIApplicationMain, int argc, char * _Nullable *argv, NSString *principalClassName, NSString *delegateClassName) {
	HBLogDebug(@"Loading Tweak");

	/*
		MusicApplication.NowPlayingViewController 			-> MusicApplication_NowPlayingViewController
		MusicApplication.TabBarController 					-> MusicApplication_TabBarController
		MusicApplication.NowPlayingQueueViewController 		-> MusicApplication_NowPlayingQueueViewController
		MusicApplication.ContainerDetailSongsViewController -> MusicApplication_ContainerDetailSongsViewController
		MusicApplication.SongsViewController 				-> MusicApplication_SongsViewController
	*/
	%init(MusicApplication_NowPlayingViewController=objc_getClass("MusicApplication.NowPlayingViewController"), MusicApplication_TabBarController=objc_getClass("MusicApplication.TabBarController"), MusicApplication_NowPlayingQueueViewController=objc_getClass("MusicApplication.NowPlayingQueueViewController"), MusicApplication_ContainerDetailSongsViewController=objc_getClass("MusicApplication.ContainerDetailSongsViewController"), MusicApplication_SongsViewController=objc_getClass("MusicApplication.SongsViewController"));
	return %orig();
}
%end

%ctor {
	%init(AppHook);

	ReloadPreferences();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)ReloadPreferences,
		CFSTR("com.haotestlabs.betterqueuingpreferences.reload"),
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
}