//
//  UIImage+OpenCV.m
//  PortraitStudio
//
//  Created by Ian Sachs on 7/8/14.
//  Copyright (c) 2014 Adobe Labs, Inc. All rights reserved.
//

#import "UIImage+OpenCV.h"
#import <Foundation/Foundation.h>

#include <opencv2/opencv.hpp>

@implementation UIImage (OpenCV)

- (id)initWithCVMat:(const cv::Mat&)cvMat
{
    // Convert from floating point if necessary
    if (CV_MAT_DEPTH(cvMat.type()) == CV_32F ||
        CV_MAT_DEPTH(cvMat.type()) == CV_64F)
    {
        cv::Mat& nonConstMat = const_cast<cv::Mat&>(cvMat);
        cvMat.convertTo(nonConstMat, CV_8UC3, 255.0);
    }
    
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                   //width
                                        cvMat.rows,                                   //height
                                        8,                                            //bits per component
                                        8 * cvMat.elemSize(),                         //bits per pixel
                                        cvMat.step[0],                                //bytesPerRow
                                        colorSpace,                                   //colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                     //CGDataProviderRef
                                        NULL,                                         //decode
                                        false,                                        //should interpolate
                                        kCGRenderingIntentDefault                     //intent
                                        );
    
    
    // Getting UIImage from CGImage
    self = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return self;
}

// TODO: @sachs correctly handle imageOrientation please
#warning Doesn't handle image orientation
- (cv::Mat)CVMat
{
    CGImageRef cgImage = self.CGImage;
    
    // Only work on 8-bit per channel images
    NSAssert(CGImageGetBitsPerComponent(cgImage) == 8, @"cvMat only works on 8bpc images");
    
    // Setup the cv::Mat
    size_t width = CGImageGetWidth(cgImage) / self.scale;
    size_t height = CGImageGetHeight(cgImage) / self.scale;
    size_t depth = CGImageGetBytesPerRow(cgImage) / width / self.scale;
    NSAssert((depth == 1 || depth == 4), @"cvMat only works on 1 and 4-channel images");
    
    cv::Mat I(static_cast<int>(height), static_cast<int>(width),
              static_cast<int>(CV_8UC(depth)));
    
    // Render this image into the cv::Mat data
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(I.data, width, height, 8, I.step[0], colorSpace, kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    //
    return I;
}

// TODO: @sachs correctly handle imageOrientation please
#warning Doesn't handle image orientation
- (cv::Mat)CVMatGray
{
    CGImageRef cgImage = self.CGImage;
    
    // Only work on 8-bit per channel images
    NSAssert(CGImageGetBitsPerComponent(cgImage) == 8, @"cvMat only works on 8bpc images");
    
    // Setup the cv::Mat
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t depth = CGImageGetBytesPerRow(cgImage) / width;
    NSAssert((depth == 1 || depth == 4), @"cvMat only works on 1 and 4-channel images");
    
    cv::Mat I(static_cast<int>(height), static_cast<int>(width), CV_8UC1);
    
    // Render this image into the cv::Mat data
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef ctx = CGBitmapContextCreate(I.data, width, height, 8, I.step[0], colorSpace, kCGImageAlphaNone);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    //
    return I;
}

- (BOOL)faceRect:(CGRect *)faceRect
{
    // Get a grayscale cv::Mat
    cv::Mat cvImage = [self CVMat];
    cv::Mat gray;
    cv::cvtColor(cvImage, gray, CV_RGB2GRAY);
    
    cv::Rect faceBounds = [self _findFaceInImage:gray];
    
    // Populate face rect if desired
    if (faceRect != nil)
    {
        faceRect->origin.x = faceBounds.x;
        faceRect->origin.y = faceBounds.y;
        faceRect->size.width = faceBounds.width;
        faceRect->size.height = faceBounds.height;
    }
    
    return (faceBounds.width > 0);
}

#pragma Private helpers

- (cv::Rect) _findFaceInImage:(const cv::Mat&) gray
{
    //load the face detector
    cv::CascadeClassifier face_det;
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"face" ofType:@"xml"];
    std::string face_detector_model_path([modelPath UTF8String]);
    if (!face_det.load(face_detector_model_path)) {
        std::cerr << "Failed loading face detector" << std::endl;
        return cv::Rect(0, 0, 0, 0);
    }
    
    //find the facial features
    cv::Mat smallImg;
    std::vector<cv::Rect> faces;
    cv::equalizeHist(gray, smallImg);
    
    UIImage *test1 = [[UIImage alloc] initWithCVMat:gray];
    UIImage *test2 = [[UIImage alloc] initWithCVMat:smallImg];
    
    face_det.detectMultiScale(smallImg,faces,1.1, 2, 0
                              |CV_HAAR_FIND_BIGGEST_OBJECT
                              |CV_HAAR_SCALE_IMAGE,
                              cv::Size(80,80));
    if (faces.size() == 0)
    {
        std::cerr << "Couldn't find a face" << std::endl;
        return cv::Rect(0, 0, 0, 0);
    }
    
    //center the rectangle slightly
    cv::Rect r = faces.at(0);
    r.y += static_cast<int>(0.2f * r.height);
    r.height = static_cast<int>(r.height*0.9f);
    r.x += static_cast<int>(0.05f * r.width);
    r.width = static_cast<int>(r.width*0.9f);
    
    return r;
}

@end
