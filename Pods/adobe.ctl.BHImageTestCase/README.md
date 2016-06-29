iOS Image Processing Test Case
==============================

XCTestCase subclass that simplifies the development of unit tests involving
image processing algorithms.

What it does
------------

An "image test case" is any test case that exercises a function that returns
an image. In these test cases, the goal is to show that a function returns
the expected image. This code simplifies that process, both by providing a 
way to generate new reference images, as well as automating the comparison of
new results with these reference images.

Why?
----

Because we write a lot of code that operates on images.

Installation with CocoaPods
---------------------------

1. Make sure your cocoapods install is set to use local pods

     ```
     $ pod repo add adobe git@git.corp.adobe.com:sachs/Specs.git
     ```

2. Add the following lines to your Podfile:

     ```
     source 'git@git.corp.adobe.com:sachs/Specs.git'
     target "Tests" do
       pod 'BHImageTestCase'
     end
     ```

   Replace "Tests" with the name of your test project.

3. Define `BH_REFERENCE_IMAGE_DIR` in `GCC_PREPROCESSOR_DEFINITIONS`. This should
   point to the directory where you want reference images to be stored. At Facebook,
   we normally use this:

     `GCC_PREPROCESSOR_DEFINITIONS = $(inherited) BH_REFERENCE_IMAGE_DIR="\"$(SOURCE_ROOT)/$(PROJECT_NAME)Tests/ReferenceImages\""`

Creating an image test
------------------------

1. Import `BHImageTestCase/BHImageTestCase.h`
2. Subclass `BHImageTestCase` instead of `XCTestCase`.
3. From within your test, use `BHImageTestMatchesReference`.
4. Run the test once with `self.recordMode = YES;` in the test's `-setUp`
   method. (This creates the reference images on disk.)
5. Remove the line enabling record mode and run the test.
