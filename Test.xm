#import "CustomHeaders/MediaPlaybackCore/MPCPlayerChangeRequest.h"

@interface FLEXBlockDescription
@property (nonatomic, readonly, nullable) NSMethodSignature *signature;
+ (FLEXBlockDescription *)describing:(id)block;
@end

#if 0
%hook MPCPlayerChangeRequest
+ (void)performRequest:(id)request completion:(id)completion {
	%orig;

	if (completion) {
		FLEXBlockDescription *desc = [%c(FLEXBlockDescription) describing:completion];
		NSMethodSignature *sign = desc.signature;

		HBLogDebug(@"Return type: %s", sign.methodReturnType);
		for (NSInteger i = 0; i < sign.numberOfArguments; i++) {
			HBLogDebug(@"\tArg %ld: %s", i, [sign getArgumentTypeAtIndex:i]);
		}
	}
}
%end
#endif

#if 1
%hook MPArtworkCatalog
-(void)requestImageWithCompletionHandler:(/*^block*/id)completion {
	%orig;

	if (completion) {
		FLEXBlockDescription *desc = [%c(FLEXBlockDescription) describing:completion];
		NSMethodSignature *sign = desc.signature;

		HBLogDebug(@"Return type: %s", sign.methodReturnType);
		HBLogDebug(@"Arg count: %lu", sign.numberOfArguments);
		for (NSInteger i = 0; i < sign.numberOfArguments; i++) {
			HBLogDebug(@"\tArg %ld: %s", i, [sign getArgumentTypeAtIndex:i]);
		}
	}
}
%end
#endif