//
//  UIImage+Transform.h
//  Lenz
//
//  Created by Ian Sachs on 4/17/14.
//  Copyright (c) 2014 Adobe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Transform)

- (UIImage *)orientUp;
- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
       interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;

@end
