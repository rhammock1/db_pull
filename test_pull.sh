#!/bin/bash
__dir="$(cd "$(dirname "$0")" && pwd)"
echo $__dir
# clear previous log contents
> $__dir/pull.log

# Find all lines matching '# FINDME' and prepend a # to the line
sed -e '/# FINDME/s/^/#/' $__dir/db_pull.sh >> $__dir/temp.sh

# test the script w/o any big commands running
bash $__dir/temp.sh ./ --force >> $__dir/pull.log

# cleanup
rm $__dir/temp.sh
