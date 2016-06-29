/*
 * Fourier burst accumulation (fba) library.
 * owang@adobe.com
 */

#include "fbaLib.h"

void fbaLib::init(std::vector<cv::Mat> _stack) {
  stack = _stack;
  nFrames = stack.size();
  width = stack[0].cols;
  height = stack[0].rows;
  nChannels = 3; // RGB

  // sigma for smoothing of Fourier weights
  auto minSize = std::min(std::min(width, height), blockSize);
  sigma = minSize / ks;

  minWeight = noiseSigma * std::sqrt(pi) * blockSize / 2.0;
  std::cout << "minweight: " << minWeight << std::endl;

  buildHanning();
  buildGaussian();
}

cv::Mat fbaLib::deblur() const {
  // std::cout << "starting deblur" << std::endl;

  // currently only works with RGBA images
  assert(stack[0].type() == CV_8UC4);

  // compute padded stack size (mirror bottom and right edges)
  auto shift = blockSize * (1.0 - blockOverlap);
  auto widthP = shift * std::ceil((width - blockSize) / shift) + blockSize;
  auto heightP = shift * std::ceil((height - blockSize) / shift) + blockSize;

  // allocate final images
  cv::Mat deblurred(height, width, CV_32FC3);
  cv::Mat deblurredNorm(height, width, CV_32FC1);
  deblurred.setTo(cv::Vec3f(0, 0, 0));
  deblurredNorm.setTo(0);

  // allocate temporary images
  cv::Mat imPatch(blockSize, blockSize, CV_32FC3);
  std::vector<cv::Mat> imPatchChannels(nChannels);
  for (auto &channel : imPatchChannels) {
    channel = cv::Mat::zeros(blockSize, blockSize, CV_32FC1);
  }

  std::vector<cv::Mat> fftPatchChannels(nChannels);
  cv::Mat fftWeights(blockSize, blockSize, CV_32FC1);
  std::vector<cv::Mat> fftAccum(nChannels);
  for (auto &channel : fftAccum) {
    channel = cv::Mat::zeros(blockSize, blockSize, CV_32FC2);
  }
  cv::Mat fftAccumNorm(blockSize, blockSize, CV_32FC1);
  // loop over all patches
  for (auto y = 0; y <= heightP - blockSize; y += shift) {
    for (auto x = 0; x <= widthP - blockSize; x += shift) {
      std::cout << "starting patch loop " << x << " " << y << std::endl;

      // clear the FFT accumulation block
      fftAccumNorm.setTo(0.0);
      for (auto &channel : fftAccum) {
        channel.setTo(cv::Scalar(0.0, 0.0));
      }

      // loop over all images
      for (auto image : stack) {

        // build FFT patch out of image
        for (auto yy = 0; yy < blockSize; ++yy) {
          for (auto xx = 0; xx < blockSize; ++xx) {
            auto imx = xx + x;
            auto imy = yy + y;

            // mirror image content when out of bounds
            if (imx >= width) {
              imx = width - (imx - width + 1) - 1;
            }
            if (imy >= height) {
              imy = height - (imy - height + 1) - 1;
            }

            auto imval = image.at<cv::Vec4b>(imy, imx);
            imPatchChannels[0].at<float>(yy, xx) = imval[0] / 255.0;
            imPatchChannels[1].at<float>(yy, xx) = imval[1] / 255.0;
            imPatchChannels[2].at<float>(yy, xx) = imval[2] / 255.0;
          }
        }

        //        cv::Mat out(imPatchChannels[0].rows, imPatchChannels[0].cols,
        //        CV_8UC1);
        //        imPatchChannels[0].convertTo(out, CV_8UC1, 255.0);

        // compute DFT of each channel
        // std::cout << "computing DFT" << std::endl;
        for (auto i = 0; i < nChannels; ++i) {
          cv::dft(imPatchChannels[i], fftPatchChannels[i],
                  cv::DFT_COMPLEX_OUTPUT);
        }

        // compute weight as average Fourier magnitude over all channels
        fftWeights.setTo(0);
        for (auto i = 0; i < nChannels; ++i) {
          for (auto yy = 0; yy < blockSize; ++yy) {
            for (auto xx = 0; xx < blockSize; ++xx) {
              auto complex = fftPatchChannels[i].at<cv::Vec2f>(yy, xx);
              auto magnitude =
                  std::sqrt(complex[0] * complex[0] + complex[1] * complex[1]);

              fftWeights.at<float>(yy, xx) += magnitude / 3.0;
            }
          }
        }


        // smooth weights
        auto kernelSize = 2.0 * (3.0 * std::round(sigma)) + 1.0;
        cv::GaussianBlur(fftWeights, fftWeights,
                         cv::Size(kernelSize, kernelSize), sigma, sigma);


        // exponentiate and max weights
        for (auto yy = 0; yy < blockSize; ++yy) {
          for (auto xx = 0; xx < blockSize; ++xx) {
            fftWeights.at<float>(yy, xx) = std::pow(
                std::max(fftWeights.at<float>(yy, xx), minWeight), softmax);
          }
        }


        // add weights to Fourier accumulation block
        // std::cout << "adding weights" << std::endl;
        // scale fft patch by weights
        for (auto i = 0; i < nChannels; ++i) {
          for (auto yy = 0; yy < blockSize; ++yy) {
            for (auto xx = 0; xx < blockSize; ++xx) {
              auto weight = fftWeights.at<float>(yy, xx);
              auto complex = fftPatchChannels[i].at<cv::Vec2f>(yy, xx);
              fftAccum[i].at<cv::Vec2f>(yy, xx)[0] += complex[0] * weight;
              fftAccum[i].at<cv::Vec2f>(yy, xx)[1] += complex[1] * weight;
            }
          }
        }
        fftAccumNorm = fftAccumNorm + fftWeights;
      }

      // normalize weighted FFT sum
      // std::cout << "normalizing fft" << std::endl;
      for (auto &channel : fftAccum) {
        for (auto yy = 0; yy < blockSize; ++yy) {
          for (auto xx = 0; xx < blockSize; ++xx) {
            auto complex = channel.at<cv::Vec2f>(yy, xx);
            auto norm = fftAccumNorm.at<float>(yy, xx);
            channel.at<cv::Vec2f>(yy, xx)[0] = complex[0] / (norm + epsilon);
            channel.at<cv::Vec2f>(yy, xx)[1] = complex[1] / (norm + epsilon);
          }
        }
      }

      // compute iFFT
      // std::cout << "inverse fft" << std::endl;
      for (auto i = 0; i < nChannels; ++i) {
        cv::idft(fftAccum[i], imPatchChannels[i],
                 cv::DFT_SCALE | cv::DFT_INVERSE | cv::DFT_REAL_OUTPUT);
      }
      cv::merge(imPatchChannels, imPatch);

      // exit(1);

      // add to accumulator image
      // std::cout << "adding to accumulator" << std::endl;
      for (auto yy = 0; yy < blockSize; ++yy) {
        for (auto xx = 0; xx < blockSize; ++xx) {
          auto imx = xx + x;
          auto imy = yy + y;

          if (imx < width && imy < height) {
            auto scaledIm =
                imPatch.at<cv::Vec3f>(yy, xx) * hanning.at<float>(yy, xx);

            deblurred.at<cv::Vec3f>(imy, imx) += scaledIm;
            deblurredNorm.at<float>(imy, imx) += hanning.at<float>(yy, xx);
          }
        }
      }
    }
  }

  //    cv::Mat rebuilt;
  //    cv::merge(imPatchChannels, deblurred);

  // normalize accumulator image
  std::vector<cv::Mat> deblurredChannels;
  cv::split(deblurred, deblurredChannels);

  std::cerr << "num channels: " << deblurredChannels.size() << std::endl;
  for (auto &channel : deblurredChannels) {
    cv::multiply(channel, 1. / deblurredNorm, channel);
  }

  cv::merge(deblurredChannels, deblurred);
  return deblurred;
}

void fbaLib::buildHanning() {
  hanning = cv::Mat::zeros(blockSize, blockSize, CV_32FC1);
  for (auto y = 0; y < blockSize; ++y) {
    for (auto x = 0; x < blockSize; ++x) {
      auto xhanningVal =
          .5 * (1 - std::cos((2.0 * pi * x) / (blockSize - 1.0)));
      auto yhanningVal =
          .5 * (1 - std::cos((2.0 * pi * y) / (blockSize - 1.0)));
      hanning.at<float>(y, x) = xhanningVal * yhanningVal + epsilon;
    }
  }
}

void fbaLib::buildGaussian() {
  auto kernelSize = 2.0 * std::round(sigma) + 1.0;
  auto kernelCenter = (kernelSize - 1) / 2.0;
  auto norm = 0.0;

  kernel = cv::Mat::zeros(kernelSize, kernelSize, CV_32FC1);
  for (auto y = 0; y < kernelSize; ++y) {
    for (auto x = 0; x < kernelSize; ++x) {
      auto gaussVal = std::exp(
          -(std::pow(x - kernelCenter, 2.0) + std::pow(y - kernelCenter, 2.0)) /
          (2.0 * sigma * sigma));
      kernel.at<float>(y, x) = gaussVal;
      norm += gaussVal;
    }
  }
  kernel = kernel / norm;
}
