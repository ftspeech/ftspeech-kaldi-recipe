#!/usr/bin/env bash

# run from egs/ftspeech dir as
#$ local/copy_dict.sh </absolute/path/to/ft_speech_data>

data_dir=$1
kaldi_data_dir=`pwd`/data


mkdir -p $kaldi_data_dir/local/dict 
cp $data_dir/lexicon/kaldi-dict/extra_questions.txt $kaldi_data_dir/local/dict || exit 1;
cp $data_dir/lexicon/kaldi-dict/lexicon.txt $kaldi_data_dir/local/dict || exit 1;
cp $data_dir/lexicon/kaldi-dict/nonsilence_phones.txt $kaldi_data_dir/local/dict || exit 1;
cp $data_dir/lexicon/kaldi-dict/optional_silence.txt $kaldi_data_dir/local/dict || exit 1;
cp $data_dir/lexicon/kaldi-dict/silence_phones.txt $kaldi_data_dir/local/dict || exit 1;


echo "Finished copying dictionary data."
