#import "BQSongProvider.h"
#import "../CustomHeaders/MediaPlayer/MPSectionedCollection.h"

@interface BQPickerDataSource : NSObject <UITableViewDataSource>
@property (nonatomic, retain) BQSongProvider *songs;
@property (nonatomic, assign) NSInteger songOffset;

- (instancetype)initWithCollection:(MPSectionedCollection *)collection collectionOffset:(NSInteger)offset;
- (BOOL)shouldUpdateWithCollection:(MPSectionedCollection *)collection;
- (void)updateWithCollection:(MPSectionedCollection *)collection;

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end