#!/bin/bash 
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

nj=1

utils/mkgraph.sh data/lang exp/tri3 exp/tri3/graph || exit 1
steps/decode.sh --nj $nj --cmd "$decode_cmd" --config conf/decode.config exp/tri3/graph data/test exp/tri3/decode
