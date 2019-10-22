#!/bin/bash 
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

nj=1

utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode
