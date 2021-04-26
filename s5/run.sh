#!/usr/bin/env bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
. ./path.sh # so python3 is on the path if not on the system (we made a link to utils/).a

nj=24
stage=0
. utils/parse_options.sh

# directory containing FT SPEECH audio and text data
# change this path to the one matching the location of ftspeech your machine
data_dir=/data/marija/ft_speech_corpus


if [ $stage -le 0 ]; then
  # Prepare kaldi text files for train, dev-balanced, dev-other, test-balanced, and test-other sets
  local/ftspeech_data_prep.sh $data_dir || exit 1;
fi


if [ $stage -le 1 ]; then
  # Prepare dict folder and LM data
  # This setup uses previously prepared data
  local/copy_dict.sh $data_dir || exit 1;
  local/copy_lm_data.sh $data_dir || exit 1;
fi


if [ $stage -le 2 ]; then
  # create the "lang" directory
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang_tmp data/lang || exit 1;
fi


if [ $stage -le 3 ]; then 
  # Extract mfccs 
  for dataset in train dev-balanced dev-other test-balanced test-other; do
    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/$dataset || exit 1;

    # Compute cepstral mean and variance normalization
    steps/compute_cmvn_stats.sh data/$dataset || exit 1;

    # Repair data set (remove corrupt data points with corrupt audio)
    utils/fix_data_dir.sh data/$dataset || exit 1;
    utils/validate_data_dir.sh data/$dataset || exit 1;

  done
  # Make a subset of the training data with the shortest 120k utterances. 
  utils/subset_data_dir.sh --shortest data/train 120000 data/train_120kshort || exit 1;
fi


if [ $stage -le 4 ]; then
  # Train 3-gram and 4-gram LMs with IRSTLM (IRSTLM must be installed and in PATH)
  #local/train_irstlm.sh data/local/lm_data/ft_lm_train_data_se.txt 3 "tg" data/lang data/local/irstlm_lms/train3_lm &> data/local/tg.log || exit 1;
  #local/train_irstlm.sh data/local/lm_data/ft_lm_train_data_se.txt 4 "fg" data/lang data/local/irstlm_lms/train4_lm &> data/local/fg.log || exit 1;

  # Use pre-trained SRILM LMs 
  local/format_pretrained_lm.sh data/local/srilm_lms/train3_lm/ft_train_kn3.lm "tg" data/lang &> data/local/tg.log || exit 1;
  local/format_pretrained_lm.sh data/local/srilm_lms/train4_lm/ft_train_kn4.lm "fg" data/lang &> data/local/fg.log || exit 1;
fi


if [ $stage -le 5 ]; then
  # Train monophone model on short utterances
  steps/train_mono.sh --nj $nj --cmd "$train_cmd" \
    data/train_120kshort data/lang exp/mono0a || exit 1;
  utils/mkgraph.sh --mono data/lang_test_tg exp/mono0a exp/mono0a/graph_tg || exit 1;
  steps/decode.sh --nj 10 --cmd "$decode_cmd" \
    exp/mono0a/graph_tg data/dev-balanced exp/mono0a/decode_tg_dev-bal || exit 1;
fi


if [ $stage -le 6 ]; then
  # Train tri1 (delta+delta-delta)
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang exp/mono0a exp/mono0a_ali || exit 1;
  steps/train_deltas.sh --cmd "$train_cmd" \
    3000 40000 data/train data/lang exp/mono0a_ali exp/tri1 || exit 1;

  # Decode dev-balanced set with both LMs
  utils/mkgraph.sh data/lang_test_tg exp/tri1 exp/tri1/graph_tg || exit 1;
  utils/mkgraph.sh data/lang_test_fg exp/tri1 exp/tri1/graph_fg || exit 1; 
  steps/decode.sh --nj 10 --cmd "$decode_cmd" \
    exp/tri1/graph_fg data/dev-balanced exp/tri1/decode_fg_dev-bal || exit 1;
  steps/decode.sh --nj 10 --cmd "$decode_cmd" \
    exp/tri1/graph_tg data/dev-balanced exp/tri1/decode_tg_dev-bal || exit 1;
fi


if [ $stage -le 7 ]; then
  # Train tri2a (delta + delta-delta)
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang exp/tri1 exp/tri1_ali || exit 1;
  steps/train_deltas.sh --cmd "$train_cmd" \
    5000 60000 data/train data/lang exp/tri1_ali exp/tri2a || exit 1;

  # Decode dev-balanced with trigram LM
  utils/mkgraph.sh data/lang_test_tg exp/tri2a exp/tri2a/graph_tg || exit 1;
  steps/decode.sh --nj 10 --cmd "$decode_cmd" \
    exp/tri2a/graph_tg data/dev-balanced exp/tri2a/decode_tg_dev-bal || exit 1;
fi



if [ $stage -le 8 ]; then
  # Train tri2b (LDA+MLLT)
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang exp/tri2a exp/tri2a_ali || exit 1;
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=5 --right-context=5" \
    6500 75000 data/train data/lang exp/tri2a_ali exp/tri2b || exit 1;

  # Decode dev-balanced with trigram LM
  utils/mkgraph.sh data/lang_test_tg exp/tri2b exp/tri2b/graph_tg || exit 1;
  steps/decode.sh --nj 10 --cmd "$decode_cmd" \
    exp/tri2b/graph_tg data/dev-balanced exp/tri2b/decode_tg_dev-bal || exit 1;
fi



if [ $stage -le 9 ]; then
  # From 2b system, train 3b which is LDA + MLLT + SAT.
  steps/align_si.sh  --nj $nj --cmd "$train_cmd" \
    --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali  || exit 1;
  steps/train_sat.sh --cmd "$train_cmd" \
    7500 100000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;

  # Decode dev with 3gram and 4gram LMs
  utils/mkgraph.sh data/lang_test_tg exp/tri3b exp/tri3b/graph_tg || exit 1;
  steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 10 \
    exp/tri3b/graph_tg data/dev-balanced exp/tri3b/decode_tg_dev-bal || exit 1;
  utils/mkgraph.sh data/lang_test_fg exp/tri3b exp/tri3b/graph_fg || exit 1;
  steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 10 \
    exp/tri3b/graph_fg data/dev-balanced exp/tri3b/decode_fg_dev-bal || exit 1;

  # Decode test with 3gram and 4gram LMs
  steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 20 \
    exp/tri3b/graph_tg data/test-balanced exp/tri3b/decode_tg_test-bal || exit 1;
  steps/decode_fmllr.sh --cmd "$decode_cmd" --nj 20 \
    exp/tri3b/graph_fg data/test-balanced exp/tri3b/decode_fg_test-bal || exit 1;
fi




if [ $stage -le 10 ]; then
  # Alignment used to train nnets and sgmms
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;
fi



# Chain TDNN
# This setup creates a new lang directory that is also used by the TDNN-LSTM system
# to resume training the neural net start from `--stage 18`
# the flag `--train_stage` can be used to resume tdnn training from a particular iteration
# e.g. local/chain/run_tdnn.sh --stage 18 --train_stage 5803
local/chain/run_tdnn.sh



# Getting results [see RESULTS file]
local/generate_results_file.sh 2> /dev/null > RESULTS
echo "Finished everything."
