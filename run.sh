#!/bin/bash

#################################################################
###    Info    ####
# http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# http://linuxcommand.org/lc3_adv_tput.php
# https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm

#################################################################
###    Config   ###

ALIGN_TOOLS_PATH=/opt/src/seq-align/
ALIGN_TOOL="$ALIGN_TOOLS_PATH"/bin/needleman_wunsch

#################################################################
PARAM_STDIN="--pass-stdin"
PARAM_STDOUT="--match-stdout"

if [ ! -x "$ALIGN_TOOL" ]; then
    echo "Cannot find dependencies, edit the ALIGN_TOOLS_PATH variable."
    exit
fi

if [ $# -lt 1 ]; then
    echo "Give a working directory of submissions (default: current directory)"
    echo "and a C source file to compile"
    echo "Also pass any execution arguments as extra parameters to this script"
    echo
    echo "Example:  $0 [submissions-dir] lab1.c [program-args] [$PARAM_STDIN file] [$PARAM_STDOUT file]"
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

function print_color {
    fg=$1
    bg=$2

    shift
    shift

    msg="$@"

    # special case for newline
    if [ "$msg" == $'\n' ]; then
        #print extra character to mark the extra newline
        echo -n "$(tput setaf $fg)$(tput setab $bg)\n$(tput sgr0)$msg"
    else
        echo -n "$(tput setaf $fg)$(tput setab $bg)$msg$(tput sgr0)"
    fi
}

function print_missing {
    print_color $COLOR_BLACK $COLOR_RED "$@"
}

function print_extra {
    print_color $COLOR_BLACK $COLOR_YELLOW "$@"
}

function print_mismatch {
    print_color $COLOR_BLACK $COLOR_MAGENTA "$@"
}

function print_output {
    output="$1"
    expected_output="$2"

    if [ "$output" == "$expected_output" ]; then
        echo "Correct output"
        return
    fi

    # echo "---------------    output    ---------------"

    _result=$($ALIGN_TOOL "~$1~" "~$2~")

    if [[ $_result =~ ~(.*)~(.*)~(.*)~ ]]; then
        _output="${BASH_REMATCH[1]}"
        _golden="${BASH_REMATCH[3]}"
    fi

    # echo "----------------------"
    # echo "$_result"
    # echo "------  output  ------"
    # echo "$_output"
    # echo "------  golden  ------"
    # echo "$_golden"
    # echo "----------------------"

    # the second parameter is the golden

    size=${#_output}
    size2=${#_golden}
    if [ $size -ne $size2 ]; then
        echo $size $size2
        print_error "bad sizes"
        echo
        return
    fi

    for (( i=0; i<$size; i++)); do
        _o=${_output:$i:1}
        _g=${_golden:$i:1}
        if [ "$_o" == "$_g" ]; then
            echo -n "$_o"
        elif [ "$_o" == "-" ]; then
            # missing character, print golden
            print_missing "$_g"
        elif [ "$_g" == "-" ]; then
            # extra character
            print_extra "$_o"
        else
            print_mismatch "$_o"
        fi
    done
}

TEMPLATE=$1
shift

# parse argumets to the porgram
EXEC_PARAMS=
STDIN=
EXPECTED=
while [ $# -ne 0 ]; do
    arg=$1;
    shift
    if [ "$arg" == "$PARAM_STDIN" ] || [ "$arg" == "$PARAM_STDOUT" ]; then
        if [ $# -eq 0 ] || [ "$1" == "$PARAM_STDOUT" ] || [ "$1" == "$PARAM_STDIN" ]; then
            print_error "$arg provided without extra arguments"
            echo
            exit
        fi
        if [ "$arg" == "$PARAM_STDIN" ]; then
            STDIN=$OLDDIR/$1
        else
            EXPECTED=$OLDDIR/$1
        fi
        shift
    elif [ -z "$STDIN" ] && [ -z "$EXPECTED" ]; then
        EXEC_PARAMS="$EXEC_PARAMS $arg"
    else
        print_error "put '$arg' before any $PARAM_STDIN and $PARAM_STDOUT"
        echo
        exit
    fi
done

if [ "$TEMPLATE" == ".c" ]; then
    echo "not a C source file"
    exit
fi

if [[ ! "${TEMPLATE}" =~ \.c$ ]]; then
    echo "not a C source file"
    exit
fi

EXEC=`basename $TEMPLATE .c`
ERRORS=`basename $TEMPLATE .c`.errors

echo "Working directory: $SRCDIR"
cd $SRCDIR

echo "Compile $TEMPLATE to $EXEC"
echo
# echo "argv      : $EXEC_PARAMS"
# echo "stdin     : $STDIN"
# echo "match with: $EXPECTED"
# echo

if [ "$EXPECTED" ]; then
    expected_output=`cat $EXPECTED`
fi

function print_legend() {
    echo -n "Color of characters: "
    print_missing "missing"
    echo -n " "
    print_extra "extra"
    echo -n " "
    print_mismatch "mismatch"
    echo
}

print_legend

function run() {
    local dir="$1"
    dir=${dir::-1}
    echo
    echo
    print_info "============================================"
    echo
    print_info "    $dir"
    echo
    print_info "============================================"
    echo
    # echo "--------------------------------------------"
    if [ ! -f "$dir"/$EXEC ]; then
        print_error "missing"
        echo
        continue
    fi

    # echo
    echo "$ ./$EXEC $EXEC_PARAMS"
    # echo "--------------------------------------------"
    # output=$(cat $STDIN |./$dir/$EXEC $EXEC_PARAMS |tee /dev/tty)
    if [ "$STDIN" ]; then
        output=$(cat $STDIN |./"$dir"/$EXEC $EXEC_PARAMS)
    else
        output=$(./"$dir"/$EXEC $EXEC_PARAMS)
    fi
    print_output "$output" "$expected_output"
    echo
}

for dir in */; do
    run "$dir"
done

cd $OLDDIR

echo
# echo "--------------------------------------------"
print_legend
echo
echo "Done"
