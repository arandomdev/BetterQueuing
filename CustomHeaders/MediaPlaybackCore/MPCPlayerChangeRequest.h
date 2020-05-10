@interface MPCPlayerChangeRequest
+ (void)performRequest:(id)request completion:(void (^)(NSError *error))completion;
@end