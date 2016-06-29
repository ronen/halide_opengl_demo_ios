//
//  ImagingFunc.h
//  PerfHarness
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#ifndef ImagingFunc_h
#define ImagingFunc_h

#include <opencv2/opencv.hpp>
#include <vector>

namespace ImagingFunc {

typedef std::vector<cv::Mat> ImageArray;

bool processImage(const cv::Mat &input, cv::Mat &output);

bool processImages(const ImageArray &inputs, cv::Mat &output);
}

#endif /* ImagingFunc_h */
