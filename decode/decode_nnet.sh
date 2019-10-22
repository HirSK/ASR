#!/bin/bash 
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

gmmdir=exp/tri3
dir=exp/dnn5b_pretrain-dbn_dnn
test_folder=/home/hirunika/kaldi/egs/mySinhalaCorpus/data/train_cv10

  steps/nnet/decode.sh --nj 10 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
    $gmmdir/graph_bd_tgpr $test_folder $dir/decode__dnn_test || exit 1;
