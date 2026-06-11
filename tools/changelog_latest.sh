#!/bin/bash

# parameters:
# 1: number of blank lines to print
# 2: file
n=$1
file=$2

# if no params are passed, print the latest changelog
if [ "$#" -ne 2 ]; then
    n=1
    file=CHANGELOG
fi

# Read the file line by line
while read line; do
    # If the line is empty, increment the blank line counter
    if [[ "$line" == "" ]]; then
        blank_line_count=$((blank_line_count+1))
    fi

    # If the blank line counter is equal to the specified number of blank lines,
    # print the current line and start printing the following lines
    if [[ $blank_line_count -eq $n ]]; then
        echo "$line"
    fi
done < "$file"
