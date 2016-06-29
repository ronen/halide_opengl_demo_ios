//
//  ImagingFunc.cpp
//  PerfHarness
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#include "ImagingFunc.h"

#include "fbaLib.h"
#include <chrono>
#include <thread>

namespace ImagingFunc {

bool processImage(const cv::Mat &input, cv::Mat &output) {

  // Pretend this is a long-running function
  std::this_thread::sleep_for(std::chrono::milliseconds(5000));

  // Test with blur
  cv::GaussianBlur(input, output, cv::Size2i(31, 31), 0.0);

  return true;
}

bool processImages(const ImageArray &inputs, cv::Mat &output) {

  fbaLib deblurrer(const_cast<std::vector<cv::Mat> &>(inputs));
  output = deblurrer.deblur();

  return true;
}
}
