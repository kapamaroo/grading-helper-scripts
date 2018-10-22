#!/bin/bash

source lab.conf

out="$(./driver.sh)"

if [ $SHOW_COLOR -eq 0 ]; then
    echo "$out"
else
    echo "$out" | head -n-1 | ./ansi2html.sh --body-only 2> /dev/null
    echo "$out" | tail -n1
fi
