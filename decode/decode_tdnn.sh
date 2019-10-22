#!/bin/bash 
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

run.sh || exit 1;
dir=exp/nnet3/tdnn_sp
#dir=exp/nnet3/tdnn_new_model_90train1
ali_dir=exp/tri3_ali
stage=11
train_stage=-10
common_egs_dir=
reporting_email=
remove_egs=true
test_folder=/home/hirukarunathilaka/kaldi/egs/mySinhalaCorpus/data/test


graph_dir=exp/tri3/graph

if [ $stage -le 11 ]; then
  for decode_set in $test_folder; do
    (
    num_jobs=`cat ${decode_set}/utt2spk|cut -d' ' -f2|sort -u|wc -l`
    steps/nnet3/decode.sh --nj $num_jobs --cmd "$decode_cmd" \
      $graph_dir $test_folder $dir/decode__tdnn_test || exit 1;

    ) &
  done
fi
wait;
exit 0;
