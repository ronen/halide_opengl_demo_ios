//
//  UIImage+Compare.h
//  
//
//  Created by Ian Sachs on 7/29/14.
//
//

#import <UIKit/UIKit.h>

/**
 UIImage comparison convenience methods.
 */
@interface UIImage (Compare)

/**
 Compare this image with another. Sizes must match.
 @param image Image to compare with
 @return YES if images are the same
 */
- (BOOL)compareWithImage:(UIImage *)image;

@end
