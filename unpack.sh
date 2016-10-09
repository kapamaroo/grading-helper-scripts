#!/bin/bash

# give the directory of submissions as parameter [default: current directory]

EXTENSIONS=".tgz .tar.gz"

OLDDIR=`pwd`
SRCDIR=`pwd`

function print_error {
    echo -n "$(tput setaf 1)$@$(tput sgr0)"
}

function print_warning {
    echo -n "$(tput setaf 5)$@$(tput sgr0)"
}

function print_info {
    echo -n "$(tput setaf 6)$@$(tput sgr0)"
}

function unpack {
    local tgz="$1"
    local ext="$2"

    expected_dir_name="`basename "$tgz" "$ext"`"
    # pipe to sort at the end to avoid duplicate names from hard links
    # subdir=`tar tvf "$tgz" |grep ^d |rev |cut -d' ' -f1 |rev |sort -u`
    subdir=`tar tf "$tgz" |grep /$ |sort -u`

    # echo
    # echo $subdir

    WARN_ON_EXEC=1
    if [ -d $subdir ]; then
        # subdirectory already exists before unpacking and may contain executables
        # from previous runs, ignore them
        WARN_ON_EXEC=0
        print_info "SKIP   "
        echo -n "$tgz"
        echo
        return
    else
        echo -n "UNPACK $tgz"
    fi

    if [ -z "$subdir" ]; then
        print_error "  -  has no subdirectory, create '$expected_dir_name'"
        mkdir -p $expected_dir_name
        tar xzf "$tgz" -C $expected_dir_name
        subdir=$expected_dir_name
    else
        subdir=${subdir::-1}
        tar xzf "$tgz"
    fi
    # basename of compressed file and compressed directory must be the same
    #
    # if [ ! -d "$expected_dir_name" ]; then
    #     print_error "  -  Name mismatch: '$expected_dir_name' instead of '$subdir'"
    # fi
    src_files=`tar tf "$tgz" |grep '.c'`
    if [ -z "$src_files" ]; then
        print_error "  -  no source code files '*.c'"
    fi
    has_executable=`find $subdir/ -executable -type f`
    if [ "$has_executable" ] && [ $WARN_ON_EXEC -eq 1 ]; then
        print_error "  -  has executable"
    fi
    # touch $subdir/notes
    cp template $subdir/notes
    echo
}

if [ $# -eq 1 ] && [ -d $1 ] && [ "$1" != "." ]; then
    SRCDIR=$1
fi

echo "Working directory: $SRCDIR"
echo
cd $SRCDIR

for ext in $EXTENSIONS; do
    # maxdepth 1, ignore leftovers of previous tries to create the compressed file
    find . -maxdepth 1 -type f -name "*$ext" -print0 | while IFS= read -r -d '' file; do
        unpack "$file" "$ext"
    done
done

cd $OLDDIR
echo
