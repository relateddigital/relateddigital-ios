//
//  RelatedDigitalDisposable.m
//  RelatedDigital
//
//  Created by Egemen Gülkılık on 22.01.2022.
//

#import "RelatedDigitalDisposable.h"

@interface RelatedDigitalDisposable ()
@property (nonatomic, copy)void (^disposalBlock)(void);
@end

@implementation RelatedDigitalDisposable

- (instancetype)init:(void (^)(void))disposalBlock {
    self = [super init];

    if (self) {
        self.disposalBlock = disposalBlock;
    }

    return self;
}

- (void)dispose {
    @synchronized(self) {
        if (self.disposalBlock) {
            self.disposalBlock();
            self.disposalBlock = nil;
        }
    }
}

@end
