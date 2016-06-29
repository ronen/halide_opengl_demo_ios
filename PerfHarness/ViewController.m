//
//  ViewController.m
//  PerfHarness
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import "ViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import "PERFImagingFunction.h"
#import "UIImage+Transform.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.image = [UIImage imageNamed:@"puppy.jpg"];
}

- (IBAction)runButtonPressed:(id)sender {
}


@end
