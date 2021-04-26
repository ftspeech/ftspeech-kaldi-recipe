#!/usr/bin/env bash

# run from egs/ftspeech dir as
#$ local/ftspeech_data_prep.sh </absolute/path/to/ft_speech_data>

data_dir=$1
kaldi_data_dir=`pwd`/data
local=`pwd`/local
utils=`pwd`/utils


for dataset in train dev-balanced dev-other test-balanced test-other; do
    # run data_prep.py for each of the coprus partitions to create text, segments, utt2spk, wav.scp
    python3 $local/data_prep.py -i $data_dir/text/ft-speech_$dataset.tsv -o $kaldi_data_dir/$dataset || exit 1;
    # create spk2utt
    $utils/utt2spk_to_spk2utt.pl $kaldi_data_dir/$dataset/utt2spk > $kaldi_data_dir/$dataset/spk2utt || exit 1;
    # validate dataset dir
    $utils/validate_data_dir.sh --no-feats $kaldi_data_dir/$dataset || exit 1;

done




