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

/tools/devskim --version

$devSkimVersion = /tools/devskim --version | tail -n 1
if [[ $devSkimVersion =~ '^0\.[6-7]\.[0-9][0-9]*']]; then # Pre 0.8
    /tools/devskim analyze "$ScanTarget" "$OutputDirectory/$3" -f sarif $Opts -g $5 --base-path $GITHUB_WORKSPACE
else # Post 0.8 
    /tools/devskim analyze --source-code "$ScanTarget" --output-file "$OutputDirectory/$3" $Opts --ignore-globs $5 --base-path $GITHUB_WORKSPACE
fi
