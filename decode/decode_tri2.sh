#!/bin/bash 
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

nj=1

utils/mkgraph.sh data/lang exp/tri2 exp/tri2/graph || exit 1
steps/decode.sh --nj $nj --cmd "$decode_cmd" --config conf/decode.config exp/tri2/graph data/test exp/tri2/decode
