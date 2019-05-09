# Defining Kaldi root directory
export KALDI_ROOT=`pwd`/../..

[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh

# Setting paths to useful tools
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh

# Enable SRILM
. $KALDI_ROOT/tools/env.sh

# Variable needed for proper data sorting
export LC_ALL=C
