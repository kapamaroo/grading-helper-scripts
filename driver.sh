#!/bin/bash

source lab.conf
source colors.conf

################################################################################

((active_len=0))
for i in "${!GRADING[@]}"; do
    if [ "${i::1}" != "-" ]; then
        ((active_len++))
    fi
done

function exit() {
    echo -n "{\"scores\": {"
    ((len=$active_len))
    for i in "${!GRADING[@]}"; do
        # echo "PRE  $i"
        if [ "${i::1}" = "-" ]; then
            continue
        fi
        ((len--))
        if [ ${NAMES[$i]+a} ]; then
            name=${NAMES[$i]}
        else
            name=$i
        fi
        echo -n "\"$name\": ${GRADING[$i]}"
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
    exit
fi

check_file "$EXTRA_FILES"

function driver() {
    local exec=$1

    echo
    echo "Compiling $LAB$exec ..."
    (make clean; make $LAB$exec)
    status=$?
    if [ ${status} -ne 0 ]; then
        return
    fi

    GRADING[$exec"_Compilation"]=100

    # echo "Running ./$LAB$exec"
    num_tests=`ls $TESTS_DIR/$exec"_out_"* |wc -l`
    for i in `seq $num_tests`; do
        if [ ! -f $TESTS_DIR/$exec"_out_"$i ]; then
            break
        fi

        if [ ! ${GRADING[$exec"_out_"$i]+a} ]; then
            continue
        fi

        if [ -f $TESTS_DIR/$exec"_in_"$i ]; then
            ./run.sh $LAB$exec --pass-stdin $TESTS_DIR/$exec"_in_"$i --match-stdout $TESTS_DIR/$exec"_out_"$i
        else
            ./run.sh $LAB$exec --match-stdout $TESTS_DIR/$exec"_out_"$i
        fi

        local result=$?

        if [ ${GRADING[$exec"_out_"$i]+a} ]; then
            GRADING[$exec"_out_"$i]=$((100 - $result))
        fi
    done
}

for exec in $EXEC_LIST; do
    driver $exec
done

exit
