#!/bin/sh

THISDIR=`pwd`
PERMFILE=${THISDIR}/PERMISSIONS

for i in $( find $THISDIR -type d -maxdepth 1 -mindepth 1 | grep -v '\.git' ); do
    cd $i
    for j in $( find . | sed 's;^\.;;' | grep -v .keep ) ; do
        grep $j $PERMFILE >/dev/null || echo $j
    done
done \
| sort -u \
| awk '{print $0" root wheel 755"}' \
>> $PERMFILE
