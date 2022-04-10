#!/bin/sh -ve
TMPFILE=`mktemp -d`
genstrings -q -SwiftUI -o "${TMPFILE}" `find Sources -name '*.swift'`
iconv -f utf-16 -t utf-8 "${TMPFILE}/Localizable.strings" > Sources/App/Resources/en.lproj/Localizable.strings
plutil -lint Sources/App/Resources/*.lproj/Localizable.strings
