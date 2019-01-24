![](https://img.shields.io/github/tag/E-B-Smith/xcode-github.svg)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/hyperium/hyper/master/LICENSE)


# xcode-github

<img height="240" src="Art/AppIcon.png" alt="Xcode-GitHub App Icon">

While working at Branch Metrics I needed a way to automate the build and test process for
our SDKs and other projects. I wrote the Xcode-GitHub macOS app that monitors new pull
requests on GitHub and creates Xcode bots to test them. 

I'd been using [Buildasaur](https://github.com/buildasaurs/Buildasaur), a great app that just chugged along for a while, but new versions of Xcode   it didn't support newer versions of Xcode and, alas, it was written in Swift 2.3 and I just didn't want to spend the effort converting the code to Swift 4 and updating the Xcode server part. 

### What's Included

* A macOS app that monitors your GitHub repos for PRs and creates new Xcode bots for them.
* A command line utility that has many of the same functions of the macOS app.
* A static library that has interfaces for GitHub and the Xcode CI system.
* An xctest test bundle for testing.

## Project Goals

### Write a useful test automation tool

### Write a new macOS app

### Experiment with macOS static libraries

### Experiment with XCTest unit tests for libraries

## Getting Started with XCode-Git

It was much easier to start over in stable Objective-C code.

## Installation and Usage

