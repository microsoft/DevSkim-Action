# $1 is the directory to scan
# $2 is if we should crawl archives
# $3 is the output filename

if [ "$1" = "GITHUB_WORKSPACE" ]; then
    Directory=$GITHUB_WORKSPACE
else
    Directory=$1
fi

if [ "$2" = "true" ]; then
    devskim analyze $Directory -f sarif -c > $GITHUB_WORKSPACE/$3
else
    devskim analyze $Directory -f sarif > $GITHUB_WORKSPACE/$3
fi