#include "MPIdentifierSet.h"

@import Foundation;

@interface MPModelObject : NSObject
@property (nonatomic,copy,readonly) MPIdentifierSet *identifiers;
@end