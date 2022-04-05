#!/bin/sh -ve
genstrings -q -SwiftUI -encoding utf8 -o Sources/App/Resources/en.lproj `find Sources -name '*.swift'`
plutil -lint Sources/App/Resources/*.lproj/Localizable.strings
