. ./cmd.sh
. ./path.sh

# Removing previously created data (from last run.sh execution)
rm -rf exp mfcc data/train/spk2utt data/train/cmvn.scp data/train/feats.scp data/train/split1 data/test/spk2utt data/test/cmvn.scp data/test/feats.scp data/test/split1 data/local/lang data/lang data/local/tmp data/local/dict/lexiconp.txt

nj=1  # split training into how many jobs?
nDecodeJobs=1

echo
echo "===== PREPARING ACOUSTIC DATA ====="
echo

# Needs to be prepared by hand (or using self written scripts):
#
# wav.scp     [<uterranceID> <full_path_to_audio_file>]
# text        [<uterranceID> <text_transcription>]
# utt2spk     [<uterranceID> <speakerID>]
# corpus.txt  [<text_transcription>]

# Making spk2utt files
utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
#utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt



echo
echo "===== PREPARING LANGUAGE DATA ====="
echo
# Needs to be prepared by hand (or using self written scripts):
#
# lexicon.txt           [<word> <phone 1> <phone 2> ...]
# nonsilence_phones.txt [<phone>]
# silence_phones.txt    [<phone>]
# optional_silence.txt  [<phone>]

# Preparing language data
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

exit

echo
echo "===== FEATURES EXTRACTION ====="
echo

#Calculating mfcc features
echo "Computing features"

utils/validate_data_dir.sh data/train     # script for checking prepared data - here: for data/train directory
utils/fix_data_dir.sh data/train          # tool for data proper sorting if needed - here: for data/train directory

mfccdir=mfcc
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir
#steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir
# Making cmvn.scp files
steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir
#steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test $mfccdir

echo "finished till here"


echo
echo "===== LANGUAGE MODEL CREATION ====="
echo "===== MAKING lm.arpa ====="
echo
loc=`which ngram-count`;
if [ -z $loc ]; then
        if uname -a | grep 64 >/dev/null; then
                sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
        else
                        sdir=$KALDI_ROOT/tools/srilm/bin/i686
        fi
        if [ -f $sdir/ngram-count ]; then
                        echo "Using SRILM language modelling tool from $sdir"
                        export PATH=$PATH:$sdir
        else
                        echo "SRILM toolkit is probably not installed.
                                Instructions: tools/install_srilm.sh"
                        exit 1
        fi
fi
local=data/local
mkdir $local/tmp
ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa
echo
echo "===== MAKING G.fst ====="
echo
lang=data/lang
arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst
echo
echo "===== MONO TRAINING ====="
echo
steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1
echo
echo "===== MONO DECODING ====="
echo
utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode
echo
echo "===== MONO ALIGNMENT ====="
echo
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1
echo
echo "===== TRI1 (first triphone pass) TRAINING ====="
echo
steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1
echo
echo "===== TRI1 (first triphone pass) DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode
echo
echo "===== run.sh script is finished ====="
echo


exit








echo
echo "===== LANGUAGE MODEL CREATION ====="
echo

#Monophone training
    #Taking subset of data for monophone training for efficiency
    #utils/subset_data_dir.sh --first data/train 10000 data/train_10k
steps/train_mono.sh --nj $nj --cmd "$train_cmd" \ 
data/train data/lang exp/mono 

#Monophone alignment
steps/align_si.sh --nj $nj --cmd "$train_cmd" \
data/train data/lang exp/mono exp/mono_ali || exit 1

echo "Begin : First triphone pass"

#tri1 [First triphone pass] 2500 allophones(HMM states) and 30000 Gaussians
steps/train_deltas.sh --cmd "$train_cmd" \
 2500 30000 data/train data/lang exp/mono_ali exp/tri1 

#tri1 decoding
utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph

steps/decode.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
 exp/tri1/graph data/train exp/tri1/decode

#tri1 alignment
steps/align_si.sh --nj $nj --cmd "$train_cmd" \
  data/train data/lang exp/tri1 exp/tri1_ali 

echo "Finish : First triphone pass"

echo "Begin : Second triphone pass"

#tri2 [a larger model than tri1]
steps/train_deltas.sh --cmd "$train_cmd" \
  3000 40000 data/train data/lang exp/tri1_ali exp/tri2

#tri2 decoding
utils/mkgraph.sh data/lang_test exp/tri2 exp/tri2/graph

steps/decode.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
 exp/tri2/graph data/train exp/tri2/decode

#tri2 alignment
steps/align_si.sh --nj $nj --cmd "$train_cmd" \
  data/train data/lang exp/tri2 exp/tri2_ali

echo "Finish : Second triphone pass"

echo "Begin : Third triphone pass"

# tri3 training [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" \
  4000 50000 data/train data/lang exp/tri1_ali exp/tri3

#tri3 decoding
utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph

exit
steps/decode.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
exp/tri3/graph data/train exp/tri3/decode

#tri3 alignment
steps/align_si.sh --nj $nj --cmd "$train_cmd"  data/train data/lang exp/tri3 exp/tri3_ali

echo "Finish : Third triphone pass"







