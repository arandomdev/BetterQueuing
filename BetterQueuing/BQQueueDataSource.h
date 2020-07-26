#import "BQSongProvider.h"
#import "../CustomHeaders/MediaPlayer/MPSectionedCollection.h"

@interface BQQueueDataSource : NSObject <UITableViewDataSource>
@property (nonatomic, retain) BQSongProvider *songs;

- (instancetype)initWithCollection:(MPSectionedCollection *)collection;
- (BOOL)shouldUpdateWithCollection:(MPSectionedCollection *)collection;
- (void)updateWithCollection:(MPSectionedCollection *)collection;

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end