#import "CustomHeaders/UIContextMenuConfiguration.h"
#import "CustomHeaders/MediaPlaybackCore/MediaPlaybackCore.h"

#import "EnhancedMusic/EMQueueViewController.h"
#import "EnhancedMusic/EMPlayerController.h"

// @interface FLEXBlockDescription
// @property (nonatomic, readonly, nullable) NSMethodSignature *signature;
// + (FLEXBlockDescription *)describing:(id)block;
// @end

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
				[controller moveItemAtIndex: indexPath.row toIndex: 0];
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

%ctor {
	HBLogDebug(@"Hooked");
	%init(NowPlayingViewController = objc_getClass("MusicApplication.NowPlayingViewController"),NowPlayingQueueViewController = objc_getClass("MusicApplication.NowPlayingQueueViewController"));
	// %init(NowPlayingQueueViewController = objc_getClass("MusicApplication.NowPlayingQueueViewController"));

	// [NSNotificationCenter.defaultCenter addObserverForName:nil object:nil queue:nil usingBlock:^void (NSNotification *note) {
	// 	HBLogDebug(@"%@, %@", note.name, note.object);
	// }];
}