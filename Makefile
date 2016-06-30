#
# This could be more DRY using some Makefile magic, but for the example
# app will try to maximize clarity by making most rules explicit
#

# Where to find Halide.
#
# If you are building this demo using Halide installed systemwide (e.g. on
# OS X installed via homebrew), you can set:
#
#  HALIDE_TOOLS_DIR = /usr/local/share/halide/tools
#  HALIDE_LIB_PATH =
#  HALIDE_INC_PATH = 
#
# These settings are for building within the Halide source tree:
#HALIDE_TOOLS_DIR = ../../tools
#HALIDE_LIB_PATH  = -L ../../bin
#HALIDE_INC_PATH  = -I ../../include
HALIDE_ROOT_DIR = /Users/ronen/github/Halide
HALIDE_TOOLS_DIR = $(HALIDE_ROOT_DIR)/tools
HALIDE_LIB_PATH  = -L $(HALIDE_ROOT_DIR)/bin
HALIDE_INC_PATH  = -I $(HALIDE_ROOT_DIR)/include

BUILD_DIR = build
TARGET_HOST = host

#
# General build settings.  Should be good cross-platform.
#
GENERATOR_LIBS = -lHalide -lz -lcurses
CXXFLAGS       = -std=c++11 -g $(HALIDE_INC_PATH)

default:	
	@echo "no default in Makfile: must specify target"

clean:
	rm -r $(BUILD_DIR)
	
# Rules to AOT-compile the halide filter for both CPU and OpenGL; the
# compiled filters depend on $(BUILD_DIR)/generate_sample_filter, which in turn
# depends on the halide filter source in sample_filter.cpp
#
$(BUILD_DIR)/sample_filter_cpu.o $(BUILD_DIR)/sample_filter_cpu.h: $(BUILD_DIR)/generate_sample_filter
	$(BUILD_DIR)/generate_sample_filter -e o,h,stmt -o $(BUILD_DIR) -f sample_filter_cpu target=$(TARGET_HOST)

$(BUILD_DIR)/sample_filter_opengl.o $(BUILD_DIR)/sample_filter_opengl.h: $(BUILD_DIR)/generate_sample_filter
	$(BUILD_DIR)/generate_sample_filter -e o,h,stmt -o $(BUILD_DIR) -f sample_filter_opengl target=$(TARGET_HOST)-opengl-debug

$(BUILD_DIR)/generate_sample_filter: sample_filter.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -fno-rtti -o $@ $^ $(HALIDE_TOOLS_DIR)/GenGen.cpp $(HALIDE_LIB_PATH) $(GENERATOR_LIBS)

#
# Build in subdir using auto-dependency mechanism
#
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) -c $(CXXFLAGS) -MMD -MF $(patsubst %.o,%.d,$@) -o $@ $<

-include $(wildcard $(BUILD_DIR)/*.d)
