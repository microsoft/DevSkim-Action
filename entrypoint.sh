#!/bin/bash

# $1 is the directory or file to scan
# $2 is if we should crawl archives
# $3 is the output filename
# $4 is the output directory
# $5 is the file globs to ignore
# $6 is the ruleids to exclude
# $7 is the path to a json file for the --options-json argument
# $8 is any additional options

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

if [ -z "$7" ]; then
    OptionsJsonArg=""
else
    OptionsJsonArg="--options-json $GITHUB_WORKSPACE/$7"
fi

if [ "$2" = "true" ]; then
    Opts="-c"
fi

if [ -z "$6" ]; then
    Idopts=""
else
    Idopts="--ignore-rule-ids $6"
fi

# Prevent glob expansion, fix ignore-globs parsing
set -o noglob

/tools/devskim analyze --source-code "$ScanTarget" --output-file "$OutputDirectory/$3" $8 $Opts --ignore-globs $5 $Idopts $OptionsJsonArg
