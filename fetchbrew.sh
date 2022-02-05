#!/bin/sh -e
ZIPFILE="Sources/App/Bundle/brew.zip"
echo "Fetching latest brew from https://github.com/App-Fair/brew (be sure to merge from upstream first)"
curl -fSL -o ${ZIPFILE} https://github.com/App-Fair/brew/zipball/HEAD 
# need to also delete the test fixtures because they contain un-signed binaries that will cause the notary service to fail
ls -lah ${ZIPFILE}
echo "Removing unneeded test support files"
zip -d ${ZIPFILE} '*/Library/Homebrew/test/support/**'
#zip -d ${ZIPFILE} '*/docs/**'
ls -lah ${ZIPFILE}
