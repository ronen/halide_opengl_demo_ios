//
//  UIImage+OpenCV.h
//  PortraitStudio
//
//  Created by Ian Sachs on 7/8/14.
//  Copyright (c) 2014 Adobe Labs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef __cplusplus
#  ifndef USE_UIIMAGE_OPENCV_IN_C
#    error "This should only be included from Objective C++"
#  endif
#else

namespace cv {
    class Mat;
}

@interface UIImage (OpenCV)

/**
 Initialize a new UIImage with the contents of cvMat
 */
- (id)initWithCVMat:(const cv::Mat&)cvMat;

/**
 Returns a cv::Mat for the pixel data stored in this image
 Will return a 1-channel image for grayscale and a 4-channel image
 for color
 */
- (cv::Mat)CVMat;

/**
 Returns a cv::Mat for the pixel data stored in this image
 Will return a 1-channel image for grayscale and a 4-channel image
 for color
 */
- (cv::Mat)CVMatGray;


/**
 */
- (BOOL)faceRect:(CGRect *)faceRect;

@end

#endif // __cplusplus
