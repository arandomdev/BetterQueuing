#import "../CustomHeaders/MediaPlaybackCore/MPCPlayerResponse.h"

@interface EMQueueDataSource : NSObject <UITableViewDataSource>
@property (nonatomic, retain) MPSectionedCollection *songs;
@property (nonatomic, retain) NSString *queueIdentifier;

- (instancetype)initWithResponse:(MPCPlayerResponse *)response;

- (bool)shouldUpdateWithResponse:(MPCPlayerResponse *)response;
- (void)updateWithResponse:(MPCPlayerResponse *)response;

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end