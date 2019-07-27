![Modernistik Cocoa Framework](https://raw.githubusercontent.com/modernistik/cocoa/master/modernistik.png)

This framework represents extension, utilizes, design patterns and practices adopted for Modernistik software development in Swift / Objective-C.

[![CI Status](https://img.shields.io/travis/modernistik/cocoa.svg?style=flat)](https://travis-ci.org/modernistik/Modernistik)
[![Version](https://img.shields.io/cocoapods/v/Modernistik.svg?style=flat)](https://cocoapods.org/pods/Modernistik)
[![License](https://img.shields.io/cocoapods/l/Modernistik.svg?style=flat)](https://cocoapods.org/pods/Modernistik)
[![Platform](https://img.shields.io/cocoapods/p/Modernistik.svg?style=flat)](https://cocoapods.org/pods/Modernistik)

## Installation

Modernistik is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Modernistik', '~> 0.5' # Swift 5+
pod 'Modernistik', '~> 0.4' # Swift 4.2+
```

#### Examples
To run the example project, clone the repo, and run `pod install` from the Examples directory first. To make it easier, you can run the `./setup.sh` script to prepare all examples..

## Core SDK
The CoreSDK (`Slate`) has several enhancements and helper methods as Swift extensions to the Swift Standard library, Foundation, CoreGraphics and UIKit. In addition it provides a set of protocols and base components that should be used when creating classes - these are usually prefixed with `Modern`. The CoreSDK is installed by default.

```ruby
pod 'Modernistik'
```

## Phoenix Queue
The Phoenix is a persistence job queue system for Swift. It allows to build idempotent and asynchronous job tasks using Foundation's `Operation` (NSOperation), that allows for jobs to be "stored" when the application is about to terminate, and be restored (resume) once the app has relaunched.

```ruby
pod 'Modernistik/Phoenix'
```

## Hyperdrive
When buildling applications that interact with Hyperdrive or [Parse Server](https://parseplatform.org/), you can include this additional subspec in order to get the additional [Parse SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) extensions as well as the Hyperdrive protocol, which should serve as a foundation for buildling a Hyperdrive-connected mobile application. To install this piece of the SDK, include `ParseSDKExtensions` in your pod declaration:

```ruby
pod 'ParseSDKExtensions' # previously Modernistik/Hyperdrive
```

## Author

Anthony Persaud, <https://www.modernistik.com>
