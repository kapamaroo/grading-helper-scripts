#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Give a working directory of submissions (default: current directory)"
    echo "and a C source file to run"
    echo "Also pass any execution arguments as extra parameters to this script"
    echo
    echo "Example:  $0 [submissions-dir] lab1.c [program-args] [$PARAM_STDIN file] [$PARAM_STDOUT file]"
    echo
    exit
fi

SCRIPTS=`dirname $(readlink -f $0)`
OLDDIR=`pwd`

SRCDIR=`pwd`
if [ -d $1 ]; then
    SRCDIR=`readlink -f $1`
    shift
fi

cd $SRCDIR

for dir in */; do
    $SCRIPTS/run.sh "$dir" $@
done

cd $OLDDIR
