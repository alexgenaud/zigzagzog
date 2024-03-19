#
# find . -name '*.zig' | entr -sc 'bash entr.test.sh'
#
NUM_ENTR=$(ps|grep "entr -[a-z][a-z]* .*sh"|wc -l|sed "s: ::g")
if [ "_$NUM_ENTR" = "_0" ]; then
    echo "Consider running 'entr -sc bash' such as:"
elif [ "_$NUM_ENTR" != "_1" ]; then
    echo "Looks like you are already running 'entr -sc bash'. Consider only one:"
    echo "find . -name '*.zig' | entr -sc 'bash entr.test.sh'"
    exit 6
fi
echo "find . -name '*.zig' | entr -sc 'bash entr.test.sh'"
echo "$(date)" 
ls -ltTor *.zig | tail -1 |sed "s/^.* \([A-Z][a-z][a-z] [0-9][0-9]* [0-9][0-9]:\)/\1/"
ls -ltr *.zig | tail -1 | sed "s:^.* ::" |  xargs zig test
