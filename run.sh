#!/bin/bash

#################################################################
###    Info    ####
# http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# http://linuxcommand.org/lc3_adv_tput.php
# https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm

source lab.conf
source colors.conf

declare -A MISMATCH=(
    ["whitespace"]=0
    ["case"]=0
    ["other"]=0
)

#################################################################
###    Config   ###

ALIGN_TOOLS_PATH=`dirname $0`
ALIGN_TOOL="$ALIGN_TOOLS_PATH"/bin/needleman_wunsch

#################################################################
PARAM_STDIN="--pass-stdin"
PARAM_STDOUT="--match-stdout"

if [ ! -x "$ALIGN_TOOL" ]; then
    echo "Cannot find dependencies, edit the ALIGN_TOOLS_PATH variable."
    exit
fi

if [ $# -lt 1 ]; then
    echo "Give a submission directory (default: current directory)"
    echo "and a C source file to run"
    echo "Also pass any execution arguments as extra parameters to this script"
    echo
    echo "Example:  $0 [submission-dir] lab1.c [program-args] [$PARAM_STDIN file] [$PARAM_STDOUT file]"
    echo
    exit
fi

OLDDIR=`pwd`

function __check_output {
    output="$1"
    expected_output="$2"

    RESULT=100

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

    local prefix="\t"
    local fix="-->\t"

    if [ $STRICT_OUTPUT -eq 0 ]; then
        ((case_ignore = 0))
        ((whitespace = 0))
        ((other = 0))
    fi
    local _res=""
    echo -n -e "$prefix"
    for (( i=0; i<$size; i++)); do
        _o=${_output:$i:1}
        _g=${_golden:$i:1}
        if [ "$_o" == "$_g" ]; then
            echo -n "$_o"
            _res+=" "
        elif [ "$_o" == "-" ]; then
            # missing character, print golden
            print_missing "$_g"
            _res+="+"
        elif [ "$_g" == "-" ]; then
            # extra character
            print_extra "$_o"
            _res+="-"
        else
            print_mismatch "$_o"
            _res+="?"
        fi
        if [ $STRICT_OUTPUT -eq 0 ] && [ "$_g" != "$_o" ]; then
            if [[ "$_g" =~ [[:space:]] ]]; then
                ((whitespace++))
            elif [[ "$_g" =~ [[:alpha:]] ]] && [ "${_g,,}" = "${_o,,}" ]; then
                ((case_ignore++))
            else
                ((other++))
            fi
        fi
        if [ "$_g" = $'\n' ]; then
            if [ $SHOW_FIXLINE -eq 1 ]; then
                if [ -n "${_res// }" ]; then
                    echo -e "$fix$_res"
                    echo
                fi
            fi
            _res=""
            echo -n -e "$prefix"
        fi
    done
    echo

    if [ $SHOW_FIXLINE -eq 1 ]; then
        if [ -n "${_res// }" ]; then
            echo -e "$fix$_res"
        fi
    fi

    if [ $STRICT_OUTPUT -eq 0 ]; then
        MISMATCH["whitespace"]=$whitespace
        MISMATCH["case"]=$case_ignore
        MISMATCH["other"]=$other
    fi
}

SRCDIR=`pwd`
if [ -d $1 ]; then
    SRCDIR=`readlink -f $1`
    shift
fi

EXEC=$1
shift

if [ ! -x $EXEC ]; then
    print_error "'$EXEC' not executable"
    echo
    exit 100
fi

function check_output {
    local output="$1"
    local expected_output="$2"

    if [ "$output" == "$expected_output" ]; then
        echo "    Correct output"
        RESULT=0
        return
    fi

    ((_res = ${MISMATCH["other"]}))
    __check_output "$output" "$expected_output"

    if [ $STRICT_OUTPUT -eq 1 ]; then
        RESULT=$_res
        return
    fi

    if [ ${MISMATCH["other"]} -gt 0 ]; then
        ((_res = ${PENALTY["other"]}))
    elif [ ${MISMATCH["whitespace"]} -gt 0 ] && [ ${MISMATCH["case"]} -gt 0 ]; then
        ((_res = ${PENALTY["whitespace"]} + ${PENALTY["case"]}))
    elif [ ${MISMATCH["whitespace"]} -gt 0 ]; then
        ((_res = ${PENALTY["whitespace"]}))
    elif [ ${MISMATCH["case"]} -gt 0 ]; then
        ((_res = ${PENALTY["case"]}))
    fi

    RESULT=$_res

    echo "    -$RESULT %"
}

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

# echo "argv      : $EXEC_PARAMS"
# echo "stdin     : $STDIN"
# echo "match with: $EXPECTED"
# echo

if [ "$STDIN" ] && [ ! -f "$STDIN" ]; then
    print_error "Missing input file: $STDIN"
    echo
    exit 100
fi

if [ "$EXPECTED" ]; then
    if [ ! -f "$EXPECTED" ]; then
        print_error "Missing output file: $EXPECTED"
        echo
        exit 100
    fi
    expected_output=`cat $EXPECTED`
fi

TIMEOUT=
if [ $TIMEOUT_LIMIT -gt 0 ]; then
    TIMEOUT="timeout $TIMEOUT_LIMIT"
fi

function print_legend() {
    if [ $SHOW_COLOR -eq 0 ]; then
        return
    fi

    echo -n "Color of characters: "
    print_missing "missing"
    echo -n " "
    print_extra "extra"
    echo -n " "
    print_mismatch "mismatch"
    echo
}

function run() {
    local dir=`basename $1`
    # echo
    print_separator
    echo
    if [ -n "$STDIN" ]; then
        print_info "    $ ./$EXEC < $(basename $STDIN) > $(basename $EXPECTED)"
    else
        print_info "    $ ./$EXEC > $(basename $EXPECTED)"
    fi
    echo
    print_separator
    echo
    # echo "--------------------------------------------"
    if [ ! -f $EXEC ]; then
        print_error "missing"
        echo
        return
    fi

    # echo
    # echo "$ ./$EXEC $EXEC_PARAMS"
    # echo "--------------------------------------------"
    # output=$(cat $STDIN |./$EXEC $EXEC_PARAMS |tee /dev/tty)
    if [ "$STDIN" ]; then
        output=$(cat $STDIN |$TIMEOUT ./$EXEC $EXEC_PARAMS)
    else
        output=$($TIMEOUT ./$EXEC $EXEC_PARAMS)
    fi

    local timeout=$?
    if [ $timeout -eq 0 ]; then
        check_output "$output" "$expected_output"
    else
        print_error "Execution takes too long (timemout = $TIMEOUT_LIMIT seconds)"
        echo
    fi
    echo
}

# print_legend

# echo "Working directory: $SRCDIR"
# echo

RESULT=0

cd $SRCDIR
run "$SRCDIR"
cd $OLDDIR

# echo
# echo "--------------------------------------------"
# print_legend
# echo
# echo "Done"

exit $RESULT
