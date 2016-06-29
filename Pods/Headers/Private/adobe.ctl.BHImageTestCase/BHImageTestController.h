//
//  BHImageTestController.h
//  
//
//  Created by Ian Sachs on 7/29/14.
//
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BHImageTestControllerErrorCode) {
    BHImageTestControllerErrorCodeUnknown,               //!< Unknown error
    BHImageTestControllerErrorCodeNeedsRecord,           //!< Missing reference
    BHImageTestControllerErrorCodePNGCreationFailed,     //!< PNG creation failed
    BHImageTestControllerErrorCodeImagesDifferentSizes,  //!< Image compare failed due to differing size
    BHImageTestControllerErrorCodeImagesDifferent        //!< Image comapre failed due to differing pixels
};

/**
 Error domain for all BHImageTest errors
 */
extern NSString *const BHImageTestErrorDomain;

/**
 Error userInfo dictionaries will sometimes use this key
 */
extern NSString *const BHImageTestReferenceImagePathKey;

/**
 Implements bulk of the BHImageTestCase functionality
 */
@interface BHImageTestController : NSObject

/**
 Directory in which reference images are stored
 */
@property (nonatomic, strong) NSString *referenceImageDirectory;

/**
 Enabled recording of new reference images
 */
@property (readwrite, nonatomic, assign) BOOL recordMode;

/**
 Main initializer.
 @param testClass The subclass of BHImageTestCase that uses this controller
 @return A new BHImageTestController instance
 */
- (instancetype)initWithTestClass:(Class)testClass;

/**
 Compare the image against the reference.
 Will also create a new reference image if recordMode = YES.
 @param image The image to check against reference (or write out as new reference)
 @param selector The test method being run
 @param identifier An optional identifier for differntiating multiple reference comparisons in a single -test method
 @param error If specified, will return something useful in the event compareImage returns NO
 @return YES if the comparison (or reference recording) is successfulå
 */
- (BOOL)compareImage:(UIImage *)image
            selector:(SEL)selector
          identifier:(NSString *)identifier
               error:(NSError **)error;

/**
 Retrieves a reference image.
 @param selector The test method being run
 @param identifier An optional identifier for differntiating multiple reference comparisons in a single -test method
 @param error If specified, will return something useful in the event compareImage returns NO
 @return The reference UIImage for the given test method and identifier
 */
- (UIImage *)referenceImageForSelector:(SEL)selector
                            identifier:(NSString *)identifier
                                 error:(NSError **)errorPtr;

@end
