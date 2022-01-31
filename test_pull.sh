#!/bin/bash

# clear previous log contents
> pull.log

# Find all lines matching '# FINDME' and prepend a # to the line
sed -e '/# FINDME/s/^/#/' db_pull.sh >> temp.sh

# test the script w/o any big commands running
bash temp.sh ./ --force >> pull.log

# cleanup
rm temp.sh
