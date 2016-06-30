# YASPWKTParser

**Please note: it have not been submitted to cocoapods repo yet!**

[![CI Status](http://img.shields.io/travis/Dmitry Dorofeev/YASPWKTParser.svg?style=flat)](https://travis-ci.org/Dmitry Dorofeev/YASPWKTParser)
[![Version](https://img.shields.io/cocoapods/v/YASPWKTParser.svg?style=flat)](http://cocoapods.org/pods/YASPWKTParser)
[![License](https://img.shields.io/cocoapods/l/YASPWKTParser.svg?style=flat)](http://cocoapods.org/pods/YASPWKTParser)
[![Platform](https://img.shields.io/cocoapods/p/YASPWKTParser.svg?style=flat)](http://cocoapods.org/pods/YASPWKTParser)

## Goals

There are several WKT parsers on github targeted iOS/OS X. They usually split POLYGON blocks by comma and use regexp for parsing coordinates. While regexps are fast, splitting means that you need two-pass scanning on possibly large text. First pass is for splitting and second pass is for regexping. 

Also, I did not find any parser which reports back parse errors and position in WKT where it failed. So I decided to implement my own WKT parser which is hopefully:

* fast
* error prone
* memory efficient

Instead of two-pass parsing I use NSScanner and C-arrays to store parsed coordinates. It is both fast and memory efficient. For example, this implementation is 4 times faster than [WKTParser](https://github.com/alejandrofcarrera/WKTParser) (As of June 2016).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

YASPWKTParser is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "YASPWKTParser"
```

## Author

Dmitry Dorofeev, dima <аt> yasp.com

## License

YASPWKTParser is available under the MIT license. See the LICENSE file for more info.
