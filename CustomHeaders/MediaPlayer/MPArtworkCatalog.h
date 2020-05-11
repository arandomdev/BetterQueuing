@interface MPArtworkCatalog
-(void)requestImageWithCompletionHandler:(void (^)(UIImage *image))completion;
@end