//
//  ViewController.m
//  opengl_demo
//
//  Created by sachs on 3/28/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

#import "ViewController.h"

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
    
    UIImage *ui_image = [UIImage imageNamed:@"puppy.jpg"];
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

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType {
    GLuint shaderHandle = glCreateShader(shaderType);    
    const char * shaderStringUTF8 = [shaderString UTF8String];    
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
 
    return shaderHandle;
 
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    GLuint texture_id;
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.image_width, self.image_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, self.image_data);

    typedef struct {
        float Position[3];
        float TexCoord[2]; // New
    } Vertex;

    const Vertex Vertices[] = {
        {{1, -1, 0}, {1, 0}},
        {{1, 1, 0}, {1, 1}},
        {{-1, 1, 0}, {0, 1}},
        {{-1, -1, 0}, {0, 0}},
    };
    const GLubyte Indices[] = {
        0, 1, 2,
        2, 3, 0
    };

    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
 
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);


    NSString *vertexShader = @" \
                            attribute vec4 Position;  \
                            attribute vec2 TexCoordIn; \
                            varying vec2 TexCoordOut; \
                            void main(void) {  \
                                gl_Position = Position; \
                                TexCoordOut = TexCoordIn; \
                            }";

    NSString *fragmentShader = @" \
                               varying lowp vec2 TexCoordOut; \
                               uniform sampler2D Texture; \
                               void main(void) { \
                                   gl_FragColor = texture2D(Texture, TexCoordOut); \
                               }";

    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, [self compileShader:vertexShader withType: GL_VERTEX_SHADER]);
    glAttachShader(programHandle, [self compileShader:fragmentShader withType: GL_FRAGMENT_SHADER]);
    glLinkProgram(programHandle);

    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }

    glUseProgram(programHandle);

    GLuint positionSlot = glGetAttribLocation(programHandle, "Position");
    GLuint texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    GLuint textureUniform = glGetUniformLocation(programHandle, "Texture");

    glEnableVertexAttribArray(positionSlot);
    glEnableVertexAttribArray(texCoordSlot);

    glViewport(0, 0, self.glk_view.frame.size.width, self.glk_view.frame.size.height);
 
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glBindTexture(GL_TEXTURE_2D, texture_id);
    glActiveTexture(GL_TEXTURE0); 
    glUniform1i(textureUniform, 0);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

- (IBAction)runButtonPressed:(id)sender {
}


@end
