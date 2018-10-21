#!/bin/bash

gcc $@ 2> errors
has_errors=$?

cat errors

# check for errors first
if [ $has_errors -ne 0 ]; then
    echo -n
elif [ -s errors ]; then
    mv errors warnings
else
    rm errors
fi

exit $has_errors
