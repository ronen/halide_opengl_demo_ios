#include <cstring>
#include <stdio.h>
#include <stdlib.h>
#include <OpenGLES/ES2/gl.h>

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


extern "C" void doit(
        const uint8_t *image_data,
        int image_width,
        int image_height,
        int window_width,
        int window_height)
{
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
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image_width, image_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_data);

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

    const GLuint positionSlot = glGetAttribLocation(programHandle, "Position");
    const GLuint texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    const GLuint textureUniform = glGetUniformLocation(programHandle, "Texture");

    glEnableVertexAttribArray(positionSlot);
    glEnableVertexAttribArray(texCoordSlot);

    glViewport(0, 0, window_width, window_height);
 
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    glBindTexture(GL_TEXTURE_2D, texture_id);
    glActiveTexture(GL_TEXTURE0); 
    glUniform1i(textureUniform, 0);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}
