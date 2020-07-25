#import "../CustomHeaders/MediaPlayer/MPSectionedCollection.h"

@interface BQQueueDataSource : NSObject <UITableViewDataSource>

- (instancetype)initWithCollection:(MPSectionedCollection *)collection;
- (BOOL)shouldUpdateWithCollection:(MPSectionedCollection *)collection;
- (void)updateWithCollection:(MPSectionedCollection *)collection;

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end