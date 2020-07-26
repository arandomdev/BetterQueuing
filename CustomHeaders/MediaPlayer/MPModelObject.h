#include "MPIdentifierSet.h"

@interface MPModelObject : NSObject
@property (nonatomic,copy,readonly) MPIdentifierSet *identifiers;
@end