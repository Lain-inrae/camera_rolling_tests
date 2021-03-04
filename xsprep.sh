#!/bin/sh

currdir=`pwd`
cd `dirname $(readlink -f $0)`

~/R/bin/Rscript $(realpath ./XSeekerPreparator.R)  \
    -i $(realpath ./data/test.rdata)         \
    -m $(realpath ./data/models.R)                 \
    -c $(realpath ./data/SERUM_v2019Jan17.tabular) \
    -o $(realpath ./test.sqlite)                   \
|| true

cd "${currdir}"
