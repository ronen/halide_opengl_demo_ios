//
//  BHImageTestController.m
//  
//
//  Created by Ian Sachs on 7/29/14.
//
//

#import "BHImageTestController.h"

#import <UIKit/UIKit.h>

#import "UIImage+Compare.h"

#import <objc/runtime.h>

NSString *const BHImageTestErrorDomain = @"com.adobe.dig.BHImageTestError";

NSString *const BHImageTestReferenceImagePathKey = @"BHImageTestReferenceImagePath";

typedef NS_ENUM(NSUInteger, BHImageTestFileNameType) {
    BHImageTestFileNameTypeReference,
    BHImageTestFileNameTypeFailedReference,
    BHImageTestFileNameTypeFailedTest,
    BHImageTestFileNameTypeFailedTestDiff,
};

@interface BHImageTestController()

@property (readonly, nonatomic, strong) Class testClass;

@end

@implementation BHImageTestController
{
    Class _testClass;
    NSFileManager *_fileManager;
}

@synthesize testClass = _testClass;

#pragma mark - Public API

- (instancetype)initWithTestClass:(Class)testClass
{
    self = [super init];
    if (self)
    {
        _testClass = testClass;
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (BOOL)compareImage:(UIImage *)image
            selector:(SEL)selector
          identifier:(NSString *)identifier
               error:(NSError **)error
{
    if (self.recordMode)
    {
        return [self _recordImage:image selector:selector identifier:identifier error:error];
    }
    else
    {
        return [self _compareImage:image selector:selector identifier:identifier error:error];
    }
}

- (UIImage *)referenceImageForSelector:(SEL)selector
                            identifier:(NSString *)identifier
                                 error:(NSError **)errorPtr
{
    NSString *filePath = [self _referenceFilePathForSelector:selector identifier:identifier];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    // Try to return a useful error if requested
    if (image == nil && errorPtr != NULL)
    {
        BOOL exists = [_fileManager fileExistsAtPath:filePath];
        if (!exists)
        {
            *errorPtr = [NSError errorWithDomain:BHImageTestErrorDomain
                                            code:BHImageTestControllerErrorCodeNeedsRecord
                                        userInfo:@{BHImageTestReferenceImagePathKey: filePath,
                                                NSLocalizedDescriptionKey: @"Unable to load reference image.",
                                                NSLocalizedFailureReasonErrorKey: @"Reference image not found. You need to run the test in record mode"}];
        }
        else
        {
            *errorPtr = [NSError errorWithDomain:BHImageTestErrorDomain
                                            code:BHImageTestControllerErrorCodeUnknown
                                        userInfo:nil];
        }
    }
    
    return image;
}

#pragma mark - Private methods
            
- (BOOL)_compareImage:(UIImage *)image
             selector:(SEL)selector
           identifier:(NSString *)identifier
                error:(NSError **)errorPtr
{
    // First check sizes
    BOOL imagesEqual = NO;
    UIImage *referenceImage = [self referenceImageForSelector:selector identifier:identifier error:errorPtr];
    if (CGSizeEqualToSize(image.size, referenceImage.size))
    {
        imagesEqual = [image compareWithImage:referenceImage];
        if (!imagesEqual)
        {
            // Write out the failed and reference image for debugging - Write out the
            // paths
            [self _saveFailedReferenceImage:referenceImage
                                  testImage:image
                                   selector:selector
                                 identifier:identifier
                                      error:errorPtr];
            
            //
            if (errorPtr != NULL)
            {
                *errorPtr = [NSError errorWithDomain:BHImageTestErrorDomain
                                                code:BHImageTestControllerErrorCodeImagesDifferent
                                            userInfo:@{NSLocalizedDescriptionKey: @"Images different"}];
            }
        }
    }
    else
    {
        if (errorPtr != NULL)
        {
            *errorPtr = [NSError errorWithDomain:BHImageTestErrorDomain
                                            code:BHImageTestControllerErrorCodeImagesDifferentSizes
                                        userInfo:@{NSLocalizedDescriptionKey: @"Images different sizes",
                                                   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"referenceImage:%@, image:%@",
                                                                                      NSStringFromCGSize(referenceImage.size),
                                                                                      NSStringFromCGSize(image.size)]}];
        }
    }
                         
    return imagesEqual;
}

- (BOOL)_recordImage:(UIImage *)image
            selector:(SEL)selector
          identifier:(NSString *)identifier
               error:(NSError **)errorPtr
{
    BOOL wroteImage = NO;
    NSString *filePath = [self _referenceFilePathForSelector:selector
                                                  identifier:identifier];

    NSData *imageData = UIImagePNGRepresentation(image);
    if (imageData != nil)
    {
        // Create the directory
        NSString *parentDirectory = [filePath stringByDeletingLastPathComponent];
        NSError *creationError = nil;
        BOOL didCreateDir = [_fileManager createDirectoryAtPath:parentDirectory
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:&creationError];
        // Failed to create the directory
        if (!didCreateDir)
        {
            if (errorPtr != NULL)
                *errorPtr = creationError;
        }
        // Success - write image
        else
        {
            wroteImage = [imageData writeToFile:filePath options:NSDataWritingAtomic error:errorPtr];
        }
    }
    else
    {
        // Error in PNG creation
        if (errorPtr != NULL)
        {
            *errorPtr = [NSError errorWithDomain:BHImageTestErrorDomain
                                            code:BHImageTestControllerErrorCodePNGCreationFailed
                                        userInfo:@{BHImageTestReferenceImagePathKey : filePath}];
        }
    }
    
    return wroteImage;
}

- (BOOL)_saveFailedReferenceImage:(UIImage *)referenceImage
                        testImage:(UIImage *)testImage
                         selector:(SEL)selector
                       identifier:(NSString *)identifier
                            error:(NSError **)errorPtr
{
    NSData *referenceData = UIImagePNGRepresentation(referenceImage);
    NSData *testData = UIImagePNGRepresentation(testImage);
    
    NSError *creationError = nil;
    NSString *failedReferencePath = [self _failedFilePathForSelector:selector
                                                          identifier:identifier
                                                   imageFileNameType:BHImageTestFileNameTypeFailedReference];
    
    BOOL didCreateDir = [_fileManager createDirectoryAtPath:[failedReferencePath stringByDeletingLastPathComponent]
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&creationError];
    if (!didCreateDir)
    {
        if (errorPtr != NULL)
            *errorPtr = creationError;
        return NO;
    }
    
    // Write the reference
    if (![referenceData writeToFile:failedReferencePath options:NSDataWritingAtomic error:errorPtr])
    {
        return NO;
    }
    
    NSString *failedTestPath = [self _failedFilePathForSelector:selector
                                                     identifier:identifier
                                              imageFileNameType:BHImageTestFileNameTypeFailedTest];
    
    // Write the failure case
    if (![testData writeToFile:failedTestPath options:NSDataWritingAtomic error:errorPtr])
    {
        return NO;
    }
    
    NSLog(@"Compare results at:\n \"%@\" \"%@\"", failedReferencePath, failedTestPath);
    return YES;
}

- (NSString *)_fileNameForSelector:(SEL)selector
                        identifier:(NSString *)identifier
                 imageFileNameType:(BHImageTestFileNameType)fileNameType
{
    NSString *fileName = @""; // Default case for the actual reference image
    
    // Write out reference and failure images
    if (fileNameType == BHImageTestFileNameTypeFailedReference)
        fileName = @"reference_";
    else if (fileNameType == BHImageTestFileNameTypeFailedTest)
        fileName = @"failed_";
    
    fileName = [fileName stringByAppendingString:NSStringFromSelector(selector)];
    if (identifier.length > 0)
    {
        fileName = [fileName stringByAppendingFormat:@"_%@", identifier];
    }
    fileName = [fileName stringByAppendingPathExtension:@"png"];
    
    return fileName;
}

- (NSString *)_referenceFilePathForSelector:(SEL)selector
                                 identifier:(NSString *)identifier
{
    NSString *fileName = [self _fileNameForSelector:selector
                                         identifier:identifier
                                  imageFileNameType:BHImageTestFileNameTypeReference];
    
    NSString *filePath = [self.referenceImageDirectory stringByAppendingPathComponent:NSStringFromClass(self.testClass)];
    filePath = [filePath stringByAppendingPathComponent:fileName];
    
    return filePath;
}

- (NSString *)_failedFilePathForSelector:(SEL)selector
                              identifier:(NSString *)identifier
                       imageFileNameType:(BHImageTestFileNameType)fileNameType
{
    NSString *fileName = [self _fileNameForSelector:selector
                                         identifier:identifier
                                  imageFileNameType:fileNameType];
    
    NSString *filePath = NSTemporaryDirectory();
    filePath = [filePath stringByAppendingPathComponent:NSStringFromClass(self.testClass)];
    filePath = [filePath stringByAppendingPathComponent:fileName];
    
    return filePath;
}




@end
