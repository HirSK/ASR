. ./cmd.sh
. ./path.sh

# split the data : 90% train 10% cross-validation (held-out)
utils/subset_data_dir_tr_cv.sh data/train data/train_tr90 data/train_cv10 || exit 1

# Pre-train DBN, i.e. a stack of RBMs
dir=exp/dnn5b_pretrain-dbn
(tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)& # forward log
$cuda_cmd $dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --rbm-iter 3 data/train $dir || exit 1;

# Train the DNN optimizing per-frame cross-entropy.
dbn=exp/dnn5b_pretrain-dbn/6.dbn  
dir=exp/dnn5b_pretrain-dbn_dnn
ali=exp/tri3_ali

feature_transform=exp/dnn5b_pretrain-dbn/final.feature_transform
(tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log

# Train
$cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn --hid-layers 6 --learn-rate 0.008 \
    data/train_tr90 data/train_cv10 data/lang $ali $ali $dir || exit 1;

# gmmdir = exp/tri3
# # Decode (reuse HCLG graph)
#   test_folder=/home/hirunika/kaldi/egs/mySinhalaCorpus/data/train_cv10
#   steps/nnet/decode.sh --nj 10 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
#     $gmmdir/graph $test_folder $dir/decode__dnn_test || exit 1;
 
 # Train

# dir=exp/dnn_Nopretrain_hidLayers_6_256t
# ali=exp/tri2_ali
# (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
# $cuda_cmd $dir/log/train_nnet.log \
#    steps/nnet/train.sh $path/train_tr90 $path/train_cv10 data/lang $ali $ali $dir || exit 1;
# --proto-opts "--activation-type=<Tanh> --hid-bias-mean=0.0 --hid-bias-range=1.0"

