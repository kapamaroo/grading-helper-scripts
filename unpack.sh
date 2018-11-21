#!/bin/bash

source lab.conf
source colors.conf

function unpack {
    local tgz="$1"
    local ext="$2"

    expected_dir_name="`basename "$tgz" "$ext"`"/
    subdir=`tar tf "$tgz" |grep /$ |sort -u`

    WARN_ON_EXEC=1
    if [[ -d "$subdir" || -d "$expected_dir_name" ]]; then
        # subdirectory already exists before unpacking and may contain executables
        # from previous runs, ignore them
        WARN_ON_EXEC=0
        print_info "SKIP   "
        echo -n "$tgz"
        print_info " --> "
        if [ -d "$subdir" ]; then
            echo -n "$subdir"
        else
            print_warning "$expected_dir_name"
        fi
        echo
        return
    # else
    #    echo -n "UNPACK $tgz"
    fi

    if [ -z "$subdir" ]; then
        print_warning "  -  no subdir"
        print_info " --> "
        print_warning "'$expected_dir_name'"
        mkdir -p "$expected_dir_name"
        tar xzf "$tgz" -C "$expected_dir_name"
        subdir="$expected_dir_name"
    else
        tar xzf "$tgz"
        if [ "$subdir" != "$expected_dir_name" ]; then
            print_warning " - move $subdir to $expected_dir_name"
            mv "$subdir" "$expected_dir_name"
            subdir="$expected_dir_name"
        fi
    fi
    echo

    src_files=`find "$subdir" -name "*.c"`
    if [ -z "$src_files" ]; then
        print_error "  -  no source code files '*.c'"
    fi
    has_executable=`find "$subdir"/ -executable -type f`
    if [ "$has_executable" ] && [ $WARN_ON_EXEC -eq 1 ]; then
        print_error "  -  has executable"
    fi
    # touch $subdir/notes
    # cp template "$subdir"/notes

    for f in $src_files; do
        echo "$(basename $f)"
        mv "$f" "$(basename "$f")"
    done

    for f in $EXTRA_FILES; do
        echo "$f"
        mv "$subdir/$f" "$f"
    done

    rm -r "$subdir"
}

if [ ! -f "$1" ]; then
    exit 100
fi
tar tf "$1" &> /dev/null
result=$?
if [ $result -ne 0 ]; then
    exit 100
fi

unpack "$1" "$2"
