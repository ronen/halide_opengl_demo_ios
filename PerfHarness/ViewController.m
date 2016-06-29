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
@property (strong, nonatomic) NSMutableArray *images;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Load the test image(s)
    UIImage *testImage1 = [UIImage imageNamed:@"REG_001.jpg"];
    UIImage *testImage2 = [UIImage imageNamed:@"REG_002.jpg"];
    UIImage *testImage3 = [UIImage imageNamed:@"REG_003.jpg"];
    UIImage *testImage4 = [UIImage imageNamed:@"REG_004.jpg"];
    UIImage *testImage5 = [UIImage imageNamed:@"REG_005.jpg"];
    UIImage *testImage6 = [UIImage imageNamed:@"REG_006.jpg"];
    UIImage *testImage7 = [UIImage imageNamed:@"REG_007.jpg"];
    UIImage *testImage8 = [UIImage imageNamed:@"REG_008.jpg"];
    UIImage *testImage9 = [UIImage imageNamed:@"REG_009.jpg"];
    UIImage *testImage10 = [UIImage imageNamed:@"REG_010.jpg"];
    
    // Add images to array
    CGSize workingSize = CGSizeMake(1536, 960);
//    CGSize workingSize = CGSizeMake(3072, 1920);
    self.images = [NSMutableArray array];
    [self.images addObject:[testImage1 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage2 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage3 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage4 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage5 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage6 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage7 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage8 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage9 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    [self.images addObject:[testImage10 resizedImage:workingSize interpolationQuality:kCGInterpolationDefault]];
    
    // Show one in the image view
    self.imageView.image = testImage1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runButtonPressed:(id)sender {
    // Run test in response to button press
    NSLog(@"Running test");
    [self performTest];
}

- (void)performTest {
    // Setup
    PERFImagingFunction *testFunction = [[PERFImagingFunction alloc] init];

    // Start the spinner
    [MBProgressHUD showHUDAddedTo:self.imageView animated:YES];

    // Run the function
    [testFunction performMultiImageOperationInBackground:self.images completionBlock:^(UIImage *result, NSError *error) {
        // Stop the spinner
        [MBProgressHUD hideHUDForView:self.imageView animated:YES];

        // Error alert
        if (error || result == nil)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Operation failed" message:@"Test operation failed" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        // Otherwise show the result
        else
        {
            self.imageView.image = result;
        }
    }];
}

@end
