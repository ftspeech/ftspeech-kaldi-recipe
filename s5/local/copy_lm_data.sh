#!/usr/bin/env bash

# run from egs/ftspeech dir as
#$ local/copy_dict.sh </absolute/path/to/ft_speech_data>

data_dir=$1
kaldi_data_dir=`pwd`/data


mkdir -p $kaldi_data_dir/local/lm_data 
cp $data_dir/lm/ft_lm_train_data_se.txt $kaldi_data_dir/local/lm_data || exit 1;

mkdir -p $kaldi_data_dir/local/srilm_lms/train3_lm $kaldi_data_dir/local/srilm_lms/train4_lm
cp $data_dir/lm/ft_train_kn3.lm $kaldi_data_dir/local/srilm_lms/train3_lm || exit 1;
cp $data_dir/lm/ft_train_kn4.lm $kaldi_data_dir/local/srilm_lms/train4_lm || exit 1;

echo "Finished copying LM data."
