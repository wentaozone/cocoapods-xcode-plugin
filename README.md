# CocoaPods for Xcode

Manage your dependencies, with minimal command line hack-fu

## Features

- Downloads and integrates CocoaPods listed in a project's Podfile
- Creates podspecs from a template
- Shows command output in the window console
- Installs documentation (from CocoaDocs) for the CocoaPods used in the open Xcode workspace
- Supports using a custom path to your CocoaPods installation

![Menu](https://github.com/kattrali/cocoadocs-xcode-plugin/raw/master/menu.png)


## Prerequisites

- Xcode 5
- CocoaPods 0.22.1+, by default expected to be installed to `/usr/local/bin/pod`. The installation path can be changed by editing `GEM PATH` in the `Product > CocoaPods` menu


## Install

Install via [Alcatraz](http://alcatraz.io/)

OR

Clone and build the project, then restart Xcode.

## Uninstall

Uninstall via [Alcatraz](http://alcatraz.io/)

OR

Run `rm -r ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/CocoaPods.xcplugin/`
