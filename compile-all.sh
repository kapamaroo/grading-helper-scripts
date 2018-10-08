#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Give a working directory of submissions (default: current directory)"
    echo "and a C source file to compile"
    echo
    echo "Example:  $0 [submissions-dir] lab1.c [extra-compiler-args]"
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
    $SCRIPTS/compile.sh "$dir" $@
done

cd $OLDDIR
