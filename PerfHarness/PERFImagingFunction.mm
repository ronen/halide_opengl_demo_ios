//
//  PERFImagingFunction.m
//  PerfHarness
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import "PERFImagingFunction.h"

#import "UIImage+OpenCV.h"
#import "PERFTimer.h"
#include <opencv2/opencv.hpp>
#include "ImagingFunc.h"

NSString *const PERFImageFunctionErrorDomain = @"com.adobe.labs.ImageProcessingHarnessError";

@implementation PERFImagingFunction

+ (dispatch_queue_t)imageProcessingQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        queue = dispatch_queue_create("com.adobe.labs.ImageProcessingHarnessQueue", 0);
    });
    return queue;
}

- (void)performSingleOperationInBackground:(UIImage *)input completionBlock:(ImageResultBlock)completionBlock
{
    cv::Mat imgIn = input.CVMat;
    __block cv::Mat imgOut;
    dispatch_async([PERFImagingFunction imageProcessingQueue], ^{
        bool success = ImagingFunc::processImage(imgIn, imgOut);
        if (success)
        {
            UIImage *result = [[UIImage alloc] initWithCVMat:imgOut];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(result, nil);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, [NSError errorWithDomain:PERFImageFunctionErrorDomain
                                                         code:PERFImageFunctionErrorFailed
                                                     userInfo:@{@"info" : @"operation failed"}]);
            });
        }
    });
}

- (void)performMultiImageOperationInBackground:(NSArray *)inputs completionBlock:(ImageResultBlock)completionBlock
{
    ImagingFunc::ImageArray images;
    for (UIImage *image in inputs)
    {
        images.emplace_back(image.CVMat);
    }
    
    __block cv::Mat imgOut;
    dispatch_async([PERFImagingFunction imageProcessingQueue], ^{
        [[PERFTimer sharedTimer:@"default"] start];
        bool success = ImagingFunc::processImages(images, imgOut);
        if (success)
        {
            UIImage *result = [[UIImage alloc] initWithCVMat:imgOut];
            [[PERFTimer sharedTimer:@"default"] logTotalTimeWithMessage:@"Completed"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(result, nil);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, [NSError errorWithDomain:PERFImageFunctionErrorDomain
                                                         code:PERFImageFunctionErrorFailed
                                                     userInfo:@{@"info" : @"operation failed"}]);
            });
        }
    });
}


@end
