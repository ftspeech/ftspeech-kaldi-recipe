#!/usr/bin/env bash

. ./path.sh || exit 1;



echo "Preparing LM for formatting"

lmfile=$1
lm_suffix=$2
srcdir=$3



test=data/lang_test_${lm_suffix}

mkdir -p $test
cp -r $srcdir/* $test

cat $lmfile | \
  arpa2fst --disambig-symbol=#0 \
           --read-symbol-table=$test/words.txt - $test/G.fst

utils/validate_lang.pl $test || exit 1;

echo "Succeeded in formatting LM."
exit 0;