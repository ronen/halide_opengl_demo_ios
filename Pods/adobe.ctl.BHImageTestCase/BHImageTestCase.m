//
//  BHImageTestCase.m
//  
//
//  Created by Ian Sachs on 7/29/14.
//
//

#import "BHImageTestCase.h"

#import "BHImageTestController.h"

@interface BHImageTestCase()

@property (nonatomic, strong) BHImageTestController *imageTestController;

@end

@implementation BHImageTestCase

@synthesize imageTestController;

- (void)setUp
{
    [super setUp];
    self.imageTestController = [[BHImageTestController alloc] initWithTestClass:[self class]];
}

- (void)tearDown
{
    self.imageTestController = nil;
    [super tearDown];
}

- (BOOL)recordMode
{
    return self.imageTestController.recordMode;
}

- (void)setRecordMode:(BOOL)recordMode
{
    self.imageTestController.recordMode = recordMode;
}

- (BOOL)compareImage:(UIImage *)image
        refDirectory:(NSString *)referenceImagesDirectory
          identifier:(NSString *)identifier
               error:(NSError *__autoreleasing *)errorPtr
{
    self.imageTestController.referenceImageDirectory = referenceImagesDirectory;
    return [self.imageTestController compareImage:image
                                         selector:self.invocation.selector
                                       identifier:identifier
                                            error:errorPtr];
}

@end
