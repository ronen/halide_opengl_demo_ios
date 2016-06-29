//
//  BHImageTestCase.h
//  
//
//  Created by Ian Sachs on 7/29/14.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

// Set up a default reference directory (should be an environment variable)
#ifndef BH_REFERENCE_IMAGE_DIR
#  warning Need to set BH_REFERENCE_IMAGE_DIR in build settings. e.g. "\"$(SOURCE_ROOT)/$(PROJECT_NAME)Tests/ReferenceImages\""
#endif

/**
 Similar to XCTAssert macros. Compares the input image with the corresponding
 reference image.
 @param resultImg The image to check against the reference
 @param identifer An optional identifer, used in the event of multiple calls within a single -test method
 */
#define BHImageTestMatchesReference(resultImg_, identifier_)                      \
do {                                                                              \
    NSError *error_ = nil;                                                        \
    NSString *refDir_ = [NSString stringWithFormat:@"%s", BH_REFERENCE_IMAGE_DIR]; \
    BOOL result_ = [self compareImage:(resultImg_) refDirectory:refDir_ identifier:(identifier_) error:&error_]; \
    XCTAssertTrue(result_, @"Image comparison failed: %@", error_);               \
    XCTAssertFalse(self.recordMode, @"Reference saved. Set recordMode = NO to rerun tests"); \
} while(0)

/**
 The base class for iOS image processing tests.
 
 In order to flip the tests in your subclass to record the reference images set `recordMode` to YES before calling
 -[super setUp].
 */
@interface BHImageTestCase : XCTestCase

/**
 When enabled, writes out the reference images to compare against
 */
@property (nonatomic, assign) BOOL recordMode;

/**
 Compares input image against reference, or records a new reference
 @param image The image to compare (recordMode == NO), or set as reference (recordMode == YES)
 @param referenceImagesDirectory The directory for reference images
 @param identifier As optional identifier for when there are multiple tests in a given -test method
 @param error As error to log in an XTCAssert macro if the test fails
 @return YES if comparison (or new reference save) succeeded
 */
- (BOOL)compareImage:(UIImage *)image
        refDirectory:(NSString *)referenceImagesDirectory
          identifier:(NSString *)identifier
               error:(NSError **)errorPtr;

@end
