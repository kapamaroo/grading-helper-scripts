#!/bin/bash

#################################################################
###    Info    ####
# http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# http://linuxcommand.org/lc3_adv_tput.php
# https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm

if [ $# -lt 1 ]; then
    echo "Give a working directory of submissions (default: current directory)"
    echo "and a C source file to compile"
    echo
    echo "Example:  $0 [submissions-dir] lab1.c"
    echo
    exit
fi

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

if [ -d $1 ]; then
    if [ "$1" != "." ]; then
        SRCDIR=$1
    fi
    shift
fi

COLOR_BLACK=0
COLOR_RED=1
COLOR_GREEN=2
COLOR_YELLOW=3
COLOR_BLUE=4
COLOR_MAGENTA=5
COLOR_CYAN=6
COLOR_WHITE=7

TEMPLATE=$1
shift

if [ "$TEMPLATE" == ".c" ]; then
    echo "not a C source file"
    exit
fi

if [[ ! "${TEMPLATE}" =~ \.c$ ]]; then
    echo "not a C source file"
    exit
fi

echo "Working directory: $SRCDIR"
cd $SRCDIR
echo

EXEC=`basename $TEMPLATE .c`
ERRORS=`basename $TEMPLATE .c`.errors

function compile() {
    local dir="$1"
    dir=${dir::-1}
    if [ ! -f "$dir"/$TEMPLATE ]; then
        print_error "MISSING "
        echo -n "$dir/"
        print_error "$TEMPLATE"
        echo
        return
    elif [ -f "$dir"/$EXEC ]; then
        print_info "SKIP    "
        echo -n "$dir/$TEMPLATE"
        echo
        return
    fi

    # remove any previous executable and errors file
    rm -rf "$dir"/$EXEC
    rm -rf "$dir"/$ERRORS

    gcc -Wall -g -lm "$dir"/$TEMPLATE -o "$dir"/$EXEC 2> "$dir"/$ERRORS
    has_errors=$?

    # check for errors first
    if [ $has_errors -ne 0 ]; then
        print_error "ERRORS  "
        echo -n "$dir/"
        print_error "$TEMPLATE"
        print_info " --> "
        print_error "$ERRORS"
        echo
        return
    else
        echo -n "CC      $dir/$TEMPLATE"
    fi

    # also check for warnings, after successful compilation
    if [ -s "$dir"/$ERRORS ]; then
        print_warning "  -  WARNINGS!  see $dir/$ERRORS"
    else
        # valid input, remove errors file
        rm -rf "$dir"/$ERRORS
    fi

    # bad_indentation=`cat -T $dir/$TEMPLATE |grep -c ^' '`
    # if [ $bad_indentation -ne 0 ]; then
    #     # print_error "  -  bad indentation, $bad_indentation lines start with SPACE"
    #     print_error "  -  indentation?"
    # fi
    echo
}

for dir in */; do
    compile "$dir"
done

cd $OLDDIR
echo
