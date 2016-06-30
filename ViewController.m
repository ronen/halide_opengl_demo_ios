//
//  ViewController.m
//  opengl_demo
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <dlfcn.h>

#import "ViewController.h"
#import "doit.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property int image_width;
@property int image_height;
@property uint8_t *image_data;
@property GLKView *glk_view;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *ui_image = [UIImage imageNamed:@"image.png"];
    CGImageRef cg_image = [ui_image CGImage];

    // self.imageView.image = ui_image
    int width = CGImageGetWidth(cg_image);
    int height = CGImageGetHeight(cg_image);

    int bytesPerRow   = (width * 4); // 4 bytes per pixel: 8 bits each of red, green, blue, and alpha.
    void *buffer = malloc( bytesPerRow * height );
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef cgcontext = CGBitmapContextCreate (buffer, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGRect rect = {{0,0},{(float)width,(float)height}};
    CGContextDrawImage(cgcontext, rect, cg_image);
    uint8_t *data = (uint8_t *) CGBitmapContextGetData (cgcontext);
    CGContextRelease(cgcontext);


    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds] context:context];

    // Configure renderbuffers created by the view
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    view.enableSetNeedsDisplay = YES;
    view.delegate = self;
    [self.view addSubview:view];

    self.image_width = width;
    self.image_height = height;
    self.image_data = data;
    self.glk_view = view;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    doit(self.image_data, self.image_width, self.image_height);
}

- (IBAction)runButtonPressed:(id)sender {
}

int halide_opengl_create_context(void *user_context) {
    // nothing to do since we only call halide with the context current
    // anyway
    return 0;
}

// This method is called by the Halide runtime to populate a function pointer
// lookup table. Since there is only one GLES implementation available on iOS
// we simply forward the lookup to dlsym
void *halide_opengl_get_proc_address(void *user_context, const char *name)
{
    void* symbol = dlsym(RTLD_NEXT,name);

    return symbol;
}


@end
