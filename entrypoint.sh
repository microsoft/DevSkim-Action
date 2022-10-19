#!/bin/bash

# $1 is the directory or file to scan
# $2 is if we should crawl archives
# $3 is the output filename
# $4 is the output directory
# $5 is the file globs to ignore

if [ "$1" = "GITHUB_WORKSPACE" ]; then
    ScanTarget=$GITHUB_WORKSPACE
else
    ScanTarget=$GITHUB_WORKSPACE/$1
fi

if [ "$4" = "GITHUB_WORKSPACE" ]; then
    OutputDirectory=$GITHUB_WORKSPACE
else
    OutputDirectory=$GITHUB_WORKSPACE/$4
fi

if [ "$2" = "true" ]; then
    Opts = "-c"
fi

echo "Scanning $ScanTarget"

/tools/devskim analyze "$ScanTarget" "$OutputDirectory/$3" -f sarif $Opts -g $5 --base-path $GITHUB_WORKSPACE