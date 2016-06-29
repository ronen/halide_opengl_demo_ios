# ios-burst-deblur-harness

This is a fork of Ian Sachs's [ios-test-harness](https://git.corp.adobe.com/sachs/ios-test-harness), with the burst deblurring code dropped into it.  The code is at `fbaLib/fbaLib.{cpp,h}`

## iOS test app

Straightforward:

* Workspace:  `PerfHarness.xcworkspace`
* Scheme: `PerfHarness`

The test app runs on images that are in `PerfHarness/TestImages/REG_*.jpg`, first resizing them to 1536x960

## OS X command line demo program

The repo includes a trivially simple command line demo program which takes a collection of images as the arguments.  E.g. to use the same images as the iOS test app:

    $ Command/burstDeblur PerfHarness/TestImages/REG_*.jpg

It writes a file `deblur.png` in the current directory.  Unlike the iOS test app, this command does not resize the files.

Build the app via:

    $ cd Command
    $ cmake .
    $ make

It presumes you have opencv installed where cmake can find it.

## Unit testing

The Xcode iOS harness includes a unit test which compares the result of operating on `PerfHarness/TestImages/REG_*.jpg` (resized) with a reference image stored in `PerfHarnessUnitTests/ReferenceImages/**/*.png`

As usual, the unit tests can be run from the commandline via

```bash
xcodebuild test -workspace PerfHarness.xcworkspace -scheme PerfHarness -sdk iphonesimulator
```

or, if you have [xcpretty](https://github.com/supermarin/xcpretty) installed,

```bash
xcodebuild test -workspace PerfHarness.xcworkspace -scheme PerfHarness -sdk iphonesimulator | tee xcodebuild.log | xcpretty
```


### Dependencies

The iOS app relies on:

- [OpenCV](https://cocoapods.org/)
- [MBProgressHUD](https://github.com/jdg/MBProgressHUD)
- [adobe.ctl.BHImageTestCase](https://git.corp.adobe.com/sachs/ios-image-test-case) (for the unit tests)

These are installed using [Cocoapods](https://cocoapods.org/) dependency manager.

The dependencies are commited into the repo (in `Pods/**`), so you shouldn't need to do anything to run it.

But if you'll be updating or changing the dependencies, you'll need to install [Cocoapods](https://cocoapods.org), see its [Getting Started](https://guides.cocoapods.org/using/getting-started.html) doc.
