# ftspeech-kaldi-recipe

This recipe is based on the Kaldi recipe [sprakbanken](https://github.com/kaldi-asr/kaldi/tree/master/egs/sprakbanken). It trains a time-delay neural network acoustic model on **FT Speech** as described in the paper [FT Speech: Danish Parliament Speech Corpus](https://isca-speech.org/archive/Interspeech_2020/abstracts/3164.html). 

Before running the recipe, you must download the [FT Speech corpus](https://ftspeech.dk) and install [Kaldi](http://kaldi-asr.org/doc/install.html) on your system. You also need Python 3.8 for data preparation and the IRSTLM toolkit if you want to train your own n-gram language models.

1. Under the Kaldi `egs/` directory, make a new subdirectory called `ft_speech` and copy the contents of this repository there, e.g., as shown below. 

```
git clone https://github.com/ftspeech/ftspeech-kaldi-recipe.git
cd ftspeech-kaldi-recipe
mkdir <kaldi-root>/egs/ft_speech
cp s5 <kaldi-root>/egs/ft_speech
```

2. Enter the newly created `ft_speech` directory under Kaldi and make soft links to the directories `steps` and `utils` from the `wsj` recipe, as shown below.

```
cd <kaldi-root>/egs/ft_speech/s5
ln -s ../../wsj/s5/steps .
ln -s ../../wsj/s5/utils .
```

3. Open the script `run.sh` in a text editor and set the variable `data_dir` to the absolute path on your system where the FT Speech data is stored. This path should contain the subdirectories `audio`, `lexicon`, `lm`, and `text`.

```
data_dir=</absolute/path/to/ft_speech_data>
```


4. Run the recipe by running the script `run.sh`. For example, the command below runs the script with no hangups (`nohup`) and redirects the output to the file `nohup_ftspeech_tdnn.out`. The recipe stores all the processed acoustic data and trained models under the working directory, so make sure you have at least 150 GB of available space on your drive.  

```
nohup ./run.sh > nohup_ftspeech_tdnn.out 2>&1
```

