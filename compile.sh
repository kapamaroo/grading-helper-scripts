#!/bin/bash

#################################################################
###    Info    ####
# http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# http://linuxcommand.org/lc3_adv_tput.php
# https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm

source lab.conf
source colors.conf

OLDDIR=`pwd`

function compile() {
    local EXEC=`basename $TEMPLATE .c`
    local ERRORS=`basename $TEMPLATE .c`.errors
    local WARNINGS=`basename $TEMPLATE .c`.warnings

    if [ ! -f $TEMPLATE ]; then
        print_error "MISSING $TEMPLATE"
        echo
        return
    elif [ -f $EXEC ]; then
        if [ -f $WARNINGS ]; then
            print_warning "SKIP    $TEMPLATE"
            print_info " --> "
            print_warning "$WARNINGS"
        else
            print_info "SKIP    "
            echo -n "$TEMPLATE"
        fi
        echo
        return
    fi

    # remove any previous executable and errors file
    rm -rf $EXEC
    rm -rf $ERRORS
    rm -rf $WARNINGS

    gcc -Wall -g $TEMPLATE $EXTRA_CFLAGS -o $EXEC 2> $ERRORS
    has_errors=$?

    # check for errors first
    if [ $has_errors -ne 0 ]; then
        print_error "CC      "
        print_error "$TEMPLATE"
        print_info " --> "
        print_error "$ERRORS"
    elif [ -s $ERRORS ]; then
        # also check for warnings, after successful compilation
        mv $ERRORS $WARNINGS
        print_warning "CC      "
        print_warning "$TEMPLATE"
        print_info " --> "
        print_warning "$WARNINGS"
    else
        # valid input, remove errors file
        echo -n "CC      $TEMPLATE"
        rm -rf $ERRORS
    fi

    # bad_indentation=`cat -T $TEMPLATE |grep -c ^' '`
    # if [ $bad_indentation -ne 0 ]; then
    #     # print_error "  -  bad indentation, $bad_indentation lines start with SPACE"
    #     print_error "  -  indentation?"
    # fi
    echo
}

if [ $# -lt 1 ]; then
    echo "Give a submission directory (default: current directory)"
    echo "and a C source file to compile"
    echo
    echo "Example:  $0 [submission-dir] lab1.c [extra-compiler-args]"
    echo
    exit
fi

SRCDIR=`pwd`
if [ -d $1 ]; then
    SRCDIR=`readlink -f $1`
    shift
fi

TEMPLATE=$1
shift

echo $TEMPLATE | grep -q -e '^[^.].*\.c$'
if [ $? -eq 1 ]; then
    echo "'$TEMPLATE' not a C source file"
    exit
fi

EXTRA_CFLAGS="$@"

echo "Working directory: $SRCDIR"
echo

cd $SRCDIR
compile $TEMPLATE
cd $OLDDIR

echo
