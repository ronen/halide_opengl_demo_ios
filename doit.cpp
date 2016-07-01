#include <cstring>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <OpenGLES/ES2/gl.h>

#include "timer.h"
#include "doit.h"

#include <HalideRuntimeOpenGL.h>
#include "build/sample_filter_cpu.h"
#include "build/sample_filter_opengl.h"

/*
 * Initializes a halide buffer_t object for 8-bit RGBA data stored
 * interleaved as rgbargba... in row-major order.
 */
static buffer_t create_buffer(int width, int height)
{
    const int channels = 4;
    const int elem_size = 1;
    buffer_t buf = {0};
    buf.stride[0] = channels;
    buf.stride[1] = channels * width;
    buf.stride[2] = 1;
    buf.elem_size = elem_size;
    buf.extent[0] = width;
    buf.extent[1] = height;
    buf.extent[2] = channels;
    // buf.host is null by initialization
    // buf.host_dirty is false by initialization
    return buf;
}

/*
 * Runs the filter on the CPU.  Takes a pointer to memory with the image
 * data to filter, and a pointer to memory in which to place the result
 * data.
 */
static std::string run_cpu_filter(const uint8_t *image_data, uint8_t *result_data, int width, int height)
{
    const auto time = Timer::start("CPU");

    // Create halide input buffer and point it at the passed image data
    auto input_buf = create_buffer(width, height);
    input_buf.host = (uint8_t *) image_data; // OK to break the const, since we know halide won't change the input

    // Create halide output buffer and point it at the passed result data storage
    auto output_buf = create_buffer(width, height);
    output_buf.host = result_data;

    // Run the AOT-compiled OpenGL filter
    sample_filter_cpu(&input_buf, &output_buf);

    return Timer::report(time);
}

/*
 * Runs the filter on OpenGL.  Takes a pointer to memory with the image
 * data to filter, and a pointer to memory in which to place the result
 * data.
 */
static std::string run_opengl_filter_from_host_to_host(const uint8_t *image_data, uint8_t *result_data, int width, int height)
{
    const auto time = Timer::start("OpenGL host-to-host");

    // Create halide input buffer and point it at the passed image data for
    // the host memory.  Halide will automatically allocate a texture to
    // hold the data on the GPU.  Mark the host memory as "dirty" so halide
    // will know it needs to transfer the data to the GPU texture.
    auto input_buf = create_buffer(width, height);
    input_buf.host = (uint8_t *) image_data; // OK to break the const, since we know halide won't change the input
    input_buf.host_dirty = true;

    // Create halide output buffer and point it at the passed result data
    // memory.  Halide will automatically allocate a texture to hold the
    // data on the GPU.
    auto output_buf = create_buffer(width, height);
    output_buf.host = result_data;

    // Run the AOT-compiled OpenGL filter
    sample_filter_opengl(&input_buf, &output_buf);
    halide_copy_to_host(nullptr, &output_buf); // Ensure that halide copies the data back to the host

    return Timer::report(time);
}

/*
 * Runs the filter on OpenGL.  Assumes the data is already in a texture,
 * and leaves the output in a texture
 */
static std::string run_opengl_filter_from_texture_to_texture(GLuint input_texture_id, GLuint output_texture_id, int width, int height)
{
    const auto time = Timer::start("OpenGL texture-to-texture");

    // Create halide input buffer and tell it to use the existing GPU
    // texture.  No need to allocate memory on the host since this simple
    // pipeline will run entirely on the GPU.
    auto input_buf = create_buffer(width, height);
    halide_opengl_wrap_texture(nullptr, &input_buf, input_texture_id);

    // Create halide output buffer and tell it to use the existing GPU texture.
    // No need to allocate memory on the host since this simple pipeline will run
    // entirely on the GPU.
    auto output_buf = create_buffer(width, height);
    halide_opengl_wrap_texture(nullptr, &output_buf, output_texture_id);

    // Run the AOT-compiled OpenGL filter
    sample_filter_opengl(&input_buf, &output_buf);

    // Tell halide we are finished using the textures
    halide_opengl_detach_texture(nullptr, &output_buf);
    halide_opengl_detach_texture(nullptr, &input_buf);

    return Timer::report(time);
}



namespace OpenGLHelpers {

    static void check_error(const char *where)
    {
        GLenum err = glGetError();
        if (err != GL_NO_ERROR) {
            fprintf(stderr,  "*************** OpenGL error %#x at %s\n", err, where);
            exit(1);
        }
    }

    static GLuint compileShader(const char *shaderString, GLenum shaderType)
    {
        const GLuint shaderHandle = glCreateShader(shaderType);    
        const int len = std::strlen(shaderString);
        glShaderSource(shaderHandle, 1, &shaderString, &len);
        glCompileShader(shaderHandle);
        GLint compileSuccess;
        glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
        if (compileSuccess == GL_FALSE) {
            GLchar messages[256];
            glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, messages);
            fprintf(stderr, "%s\n", messages);
            exit(1);
        }
        return shaderHandle;
    }

    struct program {
        GLuint positionSlot;
        GLuint texCoordSlot;
        GLuint textureUniform;
    } program;

    void setup_program()
    {
        const char *vertexShader = " \
                                    attribute vec4 Position;  \
                                    attribute vec2 TexCoordIn; \
                                    varying vec2 TexCoordOut; \
                                    void main(void) {  \
                                        gl_Position = Position; \
                                            TexCoordOut = TexCoordIn; \
                                    }";

        const char *fragmentShader = " \
                                      varying lowp vec2 TexCoordOut; \
                                      uniform sampler2D Texture; \
                                      void main(void) { \
                                          gl_FragColor = texture2D(Texture, TexCoordOut); \
                                      }";

        GLuint programHandle = glCreateProgram();
        glAttachShader(programHandle, compileShader(vertexShader, GL_VERTEX_SHADER));
        glAttachShader(programHandle, compileShader(fragmentShader, GL_FRAGMENT_SHADER));
        glLinkProgram(programHandle);

        GLint linkSuccess;
        glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
        if (linkSuccess == GL_FALSE) {
            GLchar messages[256];
            glGetProgramInfoLog(programHandle, sizeof(messages), 0, messages);
            fprintf(stderr, "%s\n", messages);
            exit(1);
        }

        glUseProgram(programHandle);
        auto positionSlot = glGetAttribLocation(programHandle, "Position");
        auto texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
        auto textureUniform = glGetUniformLocation(programHandle, "Texture");
        glEnableVertexAttribArray(positionSlot);
        glEnableVertexAttribArray(texCoordSlot);

        program.positionSlot = positionSlot;
        program.texCoordSlot = texCoordSlot;
        program.textureUniform = textureUniform;
    }

    GLuint create_texture(int width, int height, const uint8_t *data)
    {
        OpenGLHelpers::check_error("starting create_texture");
        GLuint texture_id;
        glGenTextures(1, &texture_id);
        glBindTexture(GL_TEXTURE_2D, texture_id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        OpenGLHelpers::check_error("finished create_texture");
        return texture_id;
    }

    void delete_texture(GLuint texture_id)
    {
        glDeleteTextures(1, &texture_id);
    }


    void display_texture(GLuint texture_id, float x0, float x1, float y0, float y1)
    {
        typedef struct {
            float Position[3];
            float TexCoord[2]; // New
        } Vertex;

        const Vertex Vertices[] = {
            {{x1, y0, 0}, {1, 1}},
            {{x1, y1, 0}, {1, 0}},
            {{x0, y1, 0}, {0, 0}},
            {{x0, y0, 0}, {0, 1}},
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

        glVertexAttribPointer(program.positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
        glVertexAttribPointer(program.texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
        glBindTexture(GL_TEXTURE_2D, texture_id);
        glActiveTexture(GL_TEXTURE0); 
        glUniform1i(program.textureUniform, 0);
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

        OpenGLHelpers::check_error("finished display_texture");
    }
}

namespace Layout {
    enum location { UL, UR, LL, LR };

    void draw_texture(enum location location, GLuint texture_id, int width, int height, const std::string &label)
    {
        int x0, y0;
        switch (location) {
            case LL: x0 = -1; y0 = -1; break;
            case UL: x0 = -1; y0 =  0; break;
            case LR: x0 =  0; y0 = -1; break;
            case UR: x0 =  0; y0 =  0; break;
        }
        OpenGLHelpers::display_texture(texture_id, x0, x0+1, y0, y0+1);
    }

    void draw_image(enum location location, const uint8_t *data, int width, int height, const std::string &label)
    {
        const auto texture_id = OpenGLHelpers::create_texture(width, height, data);
        draw_texture(location, texture_id, width, height, label);
        OpenGLHelpers::delete_texture(texture_id);
    }
}


extern "C" void doit(const uint8_t *image_data, int width, int height)
{
    std::string report;

    OpenGLHelpers::check_error("start");

    OpenGLHelpers::setup_program();

    OpenGLHelpers::check_error("after setup_program");

    Layout::draw_image(Layout::UL, image_data, width, height, "Input");

    OpenGLHelpers::check_error("after draw Input");

    /*
     * Draw the result of running the filter on the CPU
     */
    const auto cpu_result_data = (uint8_t *) calloc(width * height * 4, sizeof(uint8_t));
    report = run_cpu_filter(image_data, cpu_result_data, width, height);
    Layout::draw_image(Layout::UR, cpu_result_data, width, height, report);
    free((void*) cpu_result_data);

    OpenGLHelpers::check_error("after draw CPU");

    GLint fb;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fb);
    fprintf(stderr, "----------- framebuffer initial binding: %d\n", fb);

    /*
     * Draw the result of running the filter on OpenGL, with data starting
     * from and ending up on the host
     */
    const auto opengl_result_data = (uint8_t *) calloc(width * height * 4, sizeof(uint8_t));
    report = run_opengl_filter_from_host_to_host(image_data, opengl_result_data, width, height);
    Layout::draw_image(Layout::LL, image_data, width, height, report);
    free((void*) opengl_result_data);

    /*
     * Draw the result of running the filter on OpenGL, with data starting
     * from and ending up in a texture on the device
     */
    const auto image_texture_id = OpenGLHelpers::create_texture(width, height, image_data);
    const auto result_texture_id = OpenGLHelpers::create_texture(width, height, nullptr);

    report = run_opengl_filter_from_texture_to_texture(image_texture_id, result_texture_id, width, height);

    GLint fb2;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fb2);
    fprintf(stderr, "----------- framebuffer binding is now: %d\n", fb2);

    //glClearColor(1.0, 1.0, 1.0, 1.0);
    //glClear(GL_COLOR_BUFFER_BIT);
    //OpenGLHelpers::check_error("after glClear white");

    Layout::draw_texture(Layout::LR, result_texture_id, width, height, report);
    OpenGLHelpers::delete_texture(image_texture_id);
    OpenGLHelpers::delete_texture(result_texture_id);
    
    // Release all Halide internal structures for the OpenGL context
    halide_opengl_context_lost(nullptr);

}
