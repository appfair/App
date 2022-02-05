#!/bin/sh -e
echo "Fetching latest brew from https://github.com/App-Fair/brew (be sure to merge from upstream first)"
curl -fSL -o Sources/App/Bundle/brew.zip https://github.com/App-Fair/brew/zipball/HEAD 
