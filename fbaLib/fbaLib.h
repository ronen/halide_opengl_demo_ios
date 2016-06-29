/*
 * Fourier burst accumulation (fba) library.
 *
 * This project is based on the following work:
 * http://dev.ipol.im/~mdelbra/fba/
 * Duke may have ownership over the technology contained within.
 *
 * Oliver Wang
 * owang@adobe.com
 */

#ifndef FBALIB_H
#define FBALIB_H

#include <opencv2/opencv.hpp>
#include <vector>

class fbaLib {
public:
  fbaLib(std::vector<cv::Mat> &_stack) {
    setDefultParameters();
    init(_stack);
  }

public: // main routines
  void setDefultParameters() {
    // blocksize that the FFT is computed on, should be as small as possible
    // such that a good estimation of the frequency band can be achieved.
    blockSize = 512;

    // this is the fraction of the blocksize that overlaps between neighboring
    // blocks
    blockOverlap = 0.5;

    // softmax parameter, higher = more close to true max
    softmax = 11;

    // gaussian filtering of the fourier weights (lower = more
    // filtering) (as a fraction of the blocksize)
    ks = 30.0;

    // estimated sigma of gaussian noise (scale 0-1)
    noiseSigma = 3e-2;
  }

  // reinit from stack
  void init(std::vector<cv::Mat> _stack);

  // main deblur routine
  cv::Mat deblur() const;

private: // helper functions
  // build a hanning window
  void buildHanning();

  // build a 2D gaussian
  void buildGaussian();

private: // members
  // stack of aligned images
  std::vector<cv::Mat> stack;

  // image size
  int width, height, nFrames, nChannels;

  // kernel for Gaussian filtering (unused)
  cv::Mat kernel;

  // hanning window for adding overlap
  cv::Mat hanning;

public: // parameters (see setDefaultParameters for explination)
  // blocksize parameters
  int blockSize;
  double blockOverlap;

  // accumulation parameters
  double softmax;

  // noise estimation
  double noiseSigma;
  float minWeight;

  // kernel support
  double kernelSmoothness;
  double ks;
  double sigma;

  // constants
private:
  double pi = 3.14159265359;
  double epsilon = 1e-7;
};

#endif
