

MISSING_CAMERA_FILES_BEGIN_WITH=X20201203
# MISSING_CAMERA_FILES_BEGIN_WITH=

currdir=`pwd`
cd `dirname $(readlink -f $0)`

./recreate_full.R original TRUE output test.rdata begin_with "$MISSING_CAMERA_FILES_BEGIN_WITH"
( cd data ; ../annotate.sh )
./recreate_full.R input annotatediff.RData output test.rdata

~/R/bin/Rscript $(realpath ./XSeekerPreparator.R)  \
    -i $(realpath ./data/test.rdata)         \
    -m $(realpath ./data/models.R)                 \
    -c $(realpath ./data/SERUM_v2019Jan17.tabular) \
    -o $(realpath ./test.sqlite)                   \
|| true

cd "${currdir}"

