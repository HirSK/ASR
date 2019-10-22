#!/bin/bash 
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

nj=1

utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode
