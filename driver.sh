#!/bin/bash

source lab.conf
source colors.conf

################################################################################

declare -A NAMES=()

ERROR=1

((active_len=0))
for i in "${!GRADING[@]}"; do
    if [ "${i::1}" = "-" ]; then
        continue
    fi

    ((active_len++))

    IFS=',' read -a testcase <<< "${GRADING[$i]}"
    if [ -n "${testcase[1]}" ]; then
        NAMES["$i"]="${testcase[1]}"
        GRADING["$i"]=${testcase[0]}
    fi
done

function exit() {
    echo -n "{\"scores\": {"
    ((len=$active_len))
    for i in "${!GRADING[@]}"; do
        if [ "${i::1}" = "-" ]; then
            continue
        fi
        ((len--))
        if [ ${NAMES["$i"]+a} ]; then
            name=${NAMES["$i"]}
        else
            name=$i
        fi
        if [ $ERROR -eq 0 ]; then
            echo -n "\"$name\": ${GRADING[$i]}"
        else
            echo -n "\"$name\": 0"
        fi
        if [ $len -gt 0 ]; then
            echo -n ","
        fi
    done
    echo "}}"

    builtin exit $@
}

function check_file() {
    local missing=

    for file in $@; do
        if [ ! -f $file ]; then
	    echo "FAILURE: missing file: $file"
            missing="$missing $file"
        fi
    done

    if [ -n "$missing" ]; then
        echo "Submit your work again including all missing files."
        exit
    fi
}

################################################################################

echo "Getting files..."
./unpack.sh $COMPRESSED ".tar.gz"
if [ $? -ne 0 ]; then
    print_error "Cannot extract $COMPRESSED"
    echo
    GRADING["submission"]=0
    exit
fi

check_file "$EXTRA_FILES"

function driver() {
    local exec=$1

    echo
    echo "Compiling $LAB$exec ..."
    (
        make --no-print-directory clean;
        make --no-print-directory $LAB$exec
    )

    if [ -f errors ]; then
        GRADING[$exec"_compilation"]=0
        rm errors
    elif [ -f warnings ]; then
        GRADING[$exec"_compilation"]=-15
        rm warnings
    fi

    # echo "Running ./$LAB$exec"
    num_tests=`ls $TESTS_DIR/$exec"_out_"* |wc -l`
    for i in `seq $num_tests`; do
        if [ ! -f $TESTS_DIR/$exec"_out_"$i ]; then
            break
        fi

        if [ ! ${GRADING[$exec"_out_"$i]+a} ]; then
            continue
        fi

        if [ ! -f $LAB$exec ]; then
            GRADING[$exec"_out_"$i]=0
            continue
        fi

        if [ -f $TESTS_DIR/$exec"_in_"$i ]; then
            ./run.sh $LAB$exec --pass-stdin $TESTS_DIR/$exec"_in_"$i --match-stdout $TESTS_DIR/$exec"_out_"$i
        else
            ./run.sh $LAB$exec --match-stdout $TESTS_DIR/$exec"_out_"$i
        fi
        result=$?

        GRADING[$exec"_out_"$i]=$result
    done
}

ERROR=0

for exec in $EXEC_LIST; do
    driver $exec
done

print_separator
echo

exit
