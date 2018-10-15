#!/bin/bash

# give the directory of submissions as parameter [default: current directory]

EXTENSIONS=".tgz .tar.gz"

OLDDIR=`pwd`
SRCDIR=`pwd`

if [ $# -eq 1 ] && [ -d $1 ] && [ "$1" != "." ]; then
    SRCDIR=$1
fi

echo "Working directory: $SRCDIR"
echo
cd $SRCDIR

for ext in $EXTENSIONS; do
    # maxdepth 1, ignore leftovers of previous tries to create the compressed file
    find . -maxdepth 1 -type f -name "*$ext" -print0 | while IFS= read -r -d '' file; do
        file=`readlink -f "$file"`
        ./unpack.sh "$file" "$ext"
    done
done

cd $OLDDIR
echo
