#!/bin/bash

# $1 is the directory or file to scan
# $2 is if we should crawl archives
# $3 is the output filename
# $4 is the output directory

if [ "$1" = "GITHUB_WORKSPACE" ]; then
    ScanTarget=$GITHUB_WORKSPACE
else
    ScanTarget=$1
fi

if [ "$4" = "GITHUB_WORKSPACE" ]; then
    OutputDirectory=$GITHUB_WORKSPACE
else
    OutputDirectory=$4
fi

if [ "$2" = "true" ]; then
    /tools/devskim analyze $ScanTarget -f sarif -c > $OutputDirectory/$3
else
    /tools/devskim analyze $ScanTarget -f sarif > $OutputDirectory/$3
fi