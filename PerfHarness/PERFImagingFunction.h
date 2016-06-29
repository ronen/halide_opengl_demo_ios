//
//  PERFImagingFunction.h
//  PerfHarness
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *const PERFImageFunctionErrorDomain;

typedef NS_ENUM(NSInteger, PERFImageFunctionError) {
    PERFImageFunctionErrorFailed = -1
};

typedef void(^ImageResultBlock)(UIImage *, NSError *);

@interface PERFImagingFunction : NSObject

- (void)performSingleImageOperationInBackground:(UIImage *)input completionBlock:(ImageResultBlock)completionBlock;

- (void)performMultiImageOperationInBackground:(NSArray *)inputs completionBlock:(ImageResultBlock)completionBlock;

@end
