# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e

#
# Data preprocessing configuration
#

N_MONO=10000000  # number of monolingual sentences for each language
N_THREADS=16    # number of threads in data preprocessing
SRC=en           # source language
TGT=sen           # target language
Sent=500000      # monolingual data used in back-translation

#
# Initialize Moses and data paths
#

# main paths
UMT_PATH=$PWD
DATA_PATH=$PWD/data
TOOLS_PATH=$PWD/tools
MONO_PATH=$DATA_PATH/mono
PARA_PATH=$DATA_PATH/para
EMB_PATH=$DATA_PATH/embeddings

# create paths
mkdir -p $DATA_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH
mkdir -p $EMB_PATH





# moses
MOSES_PATH=/home/qiang/Desktop/UnsupervisedMT-master/PBSMT/tools/mosesdecoder  # PATH_WHERE_YOU_INSTALLED_MOSES
TOKENIZER=$MOSES_PATH/scripts/tokenizer/tokenizer.perl
NORM_PUNC=$MOSES_PATH/scripts/tokenizer/normalize-punctuation.perl
INPUT_FROM_SGM=$MOSES_PATH/scripts/ems/support/input-from-sgm.perl
REM_NON_PRINT_CHAR=$MOSES_PATH/scripts/tokenizer/remove-non-printing-char.perl
TRAIN_TRUECASER=$MOSES_PATH/scripts/recaser/train-truecaser.perl
TRUECASER=$MOSES_PATH/scripts/recaser/truecase.perl
DETRUECASER=$MOSES_PATH/scripts/recaser/detruecase.perl
TRAIN_LM=$MOSES_PATH/bin/lmplz
TRAIN_MODEL=$MOSES_PATH/scripts/training/train-model.perl
MULTIBLEU=$MOSES_PATH/scripts/generic/multi-bleu.perl
MOSES_BIN=$MOSES_PATH/bin/moses


# training directory
TRAIN_DIR=$PWD/moses_train_$SRC-$TGT

# MUSE path
MUSE_PATH=$PWD/MUSE

# files full paths
SRC_RAW=$MONO_PATH/wiki_FKScore_hard.$SRC
TGT_RAW=$MONO_PATH/wiki_FKScore_simple.$TGT
SRC_TOK=$MONO_PATH/all.$SRC.tok
TGT_TOK=$MONO_PATH/all.$TGT.tok
SRC_TRUE=$MONO_PATH/all.$SRC.true
TGT_TRUE=$MONO_PATH/all.$TGT.true
SRC_VALID=$DATA_PATH/para/dev/valid.$SRC
TGT_VALID=$DATA_PATH/para/dev/valid.$TGT
SRC_TEST=$DATA_PATH/para/dev/test.$SRC
TGT_TEST=$DATA_PATH/para/dev/test.$TGT
SRC_TRUECASER=$DATA_PATH/$SRC.truecaser
TGT_TRUECASER=$DATA_PATH/$TGT.truecaser
SRC_LM_ARPA=$DATA_PATH/$SRC.lm.arpa
TGT_LM_ARPA=$DATA_PATH/$TGT.lm.arpa
SRC_LM_BLM=$DATA_PATH/$SRC.lm.blm
TGT_LM_BLM=$DATA_PATH/$TGT.lm.blm


# Download MUSE
if [ ! -d "$MUSE_PATH" ]; then
  echo "Cloning MUSE from GitHub repository..."
  git clone https://github.com/facebookresearch/MUSE.git
  cd $MUSE_PATH/data/
  ./get_evaluation.sh
fi
echo "MUSE found in: $MUSE_PATH"





cd $MONO_PATH

# tokenize data
if ! [[ -f "$SRC_TOK" && -f "$TGT_TOK" ]]; then
  echo "Tokenize monolingual data..."
  cat $SRC_RAW | head -n $N_MONO | $NORM_PUNC -l $SRC | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS > $SRC_TOK
  cat $TGT_RAW | head -n $N_MONO | $NORM_PUNC -l $SRC | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS > $TGT_TOK
fi

echo "$SRC monolingual data tokenized in: $SRC_TOK"
echo "$TGT monolingual data tokenized in: $TGT_TOK"

# learn truecasers
if ! [[ -f "$SRC_TRUECASER" && -f "$TGT_TRUECASER" ]]; then
  echo "Learning truecasers..."
  $TRAIN_TRUECASER --model $SRC_TRUECASER --corpus $SRC_TOK
  $TRAIN_TRUECASER --model $TGT_TRUECASER --corpus $TGT_TOK
fi
echo "$SRC truecaser in: $SRC_TRUECASER"
echo "$TGT truecaser in: $TGT_TRUECASER"

# truecase data
if ! [[ -f "$SRC_TRUE" && -f "$TGT_TRUE" ]]; then
  echo "Truecsing monolingual data..."
  $TRUECASER --model $SRC_TRUECASER < $SRC_TOK > $SRC_TRUE
  $TRUECASER --model $TGT_TRUECASER < $TGT_TOK > $TGT_TRUE
fi
echo "$SRC monolingual data truecased in: $SRC_TRUE"
echo "$TGT monolingual data truecased in: $TGT_TRUE"

# learn language models
if ! [[ -f "$SRC_LM_ARPA" && -f "$TGT_LM_ARPA" ]]; then
  echo "Learning language models..."
  $TRAIN_LM -o 5 < $SRC_TRUE > $SRC_LM_ARPA
  $TRAIN_LM -o 5 < $TGT_TRUE > $TGT_LM_ARPA
fi
echo "$SRC language model in: $SRC_LM_ARPA"
echo "$TGT language model in: $TGT_LM_ARPA"

# binarize language models
if ! [[ -f "$SRC_LM_BLM" && -f "$TGT_LM_BLM" ]]; then
  echo "Binarizing language models..."
  $MOSES_PATH/bin/build_binary $SRC_LM_ARPA $SRC_LM_BLM
  $MOSES_PATH/bin/build_binary $TGT_LM_ARPA $TGT_LM_BLM
fi

echo "$SRC binarized language model in: $SRC_LM_BLM"
echo "$TGT binarized language model in: $TGT_LM_BLM"


#
# Generating a phrase-table in an unsupervised way
#

PHRASE_TABLE_PATH=$MUSE_PATH/alignments/wiki-released-$SRC$TGT-identical_char/phrase-table.$SRC-$TGT.gz
if ! [[ -f "$PHRASE_TABLE_PATH" ]]; then
  echo "Generating unsupervised phrase-table"
  python $UMT_PATH/create-phrase-table.py \
  --src_lang $SRC \
  --tgt_lang $TGT \
  --src_emb $EMB_PATH/wiki.en.300.vec \
  --tgt_emb $EMB_PATH/wiki.en.300.vec \
  --csls 1 \
  --max_rank 200 \
  --max_vocab 50000 \
  --inverse_score 1 \
  --temperature 45 \
  --phrase_table_path ${PHRASE_TABLE_PATH::-3}
fi
echo "Phrase-table location: $PHRASE_TABLE_PATH"

#
# Train Moses on the generated phrase-table
#

rm -rf $TRAIN_DIR
echo "Generating Moses configuration in: $TRAIN_DIR"

echo "Creating default configuration file..."
$TRAIN_MODEL -root-dir $TRAIN_DIR \
-f $SRC -e $TGT -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
-lm 0:5:$TGT_LM_BLM:8 -external-bin-dir $MOSES_PATH/tools \
-cores $N_THREADS -first-step=9 -last-step=9 -score-options "OnlyDirect" 
CONFIG_PATH=$TRAIN_DIR/model/moses.ini

echo "Removing lexical reordering features ..."
mv $TRAIN_DIR/model/moses.ini $TRAIN_DIR/model/moses.ini.bkp
cat $TRAIN_DIR/model/moses.ini.bkp | grep -v LexicalReordering > $TRAIN_DIR/model/moses.ini

echo "Linking phrase-table path..."
ln -sf $PHRASE_TABLE_PATH $TRAIN_DIR/model/phrase-table.gz

echo "Translating test sentences..."
$MOSES_BIN -threads $N_THREADS -f $CONFIG_PATH < $SRC_TEST.true > $TRAIN_DIR/test.$TGT.hyp.true

echo "Detruecasing hypothesis..."
$DETRUECASER < $TRAIN_DIR/test.$TGT.hyp.true > $TRAIN_DIR/test.$TGT.hyp.tok

echo "Evaluating translations..."
$MULTIBLEU $TGT_TEST.true < $TRAIN_DIR/test.$TGT.hyp.true > $TRAIN_DIR/eval.true.${SRC}2${TGT}

cat $TRAIN_DIR/eval.true.${SRC}2${TGT}

echo "Back Translate procedure..."

# add the back-translation procedure here @9.10.2018, first iteration
epoch=1
TRAIN_DIR_ITER_FORWARD=${TRAIN_DIR}-${epoch}-forward
mkdir -p $TRAIN_DIR_ITER_FORWARD
mkdir -p $TRAIN_DIR_ITER_FORWARD/model
# copy the initial model in first epoch
cp ${CONFIG_PATH} $TRAIN_DIR_ITER_FORWARD/model/moses.ini
echo "Linking phrase-table path..."
ln -sf $PHRASE_TABLE_PATH $TRAIN_DIR_ITER_FORWARD/model/phrase-table.gz


for epoch in {1..5}; do
  
  echo "Iteration", ${epoch}

  echo "Translating monolingual data..."
  # translate the monolingual data from random sample 50m sentence (SRC to TGT)
  shuf -n ${Sent} $SRC_TRUE > $SRC_TRUE.sample.${Sent}.${epoch}.${SRC}

  

  $MOSES_BIN  -f $TRAIN_DIR_ITER_FORWARD/model/moses.ini < $SRC_TRUE.sample.${Sent}.${epoch}.${SRC} > $SRC_TRUE.sample.${Sent}.${epoch}.${TGT}
  # train another model with direction (TGT to SRC)
  TRAIN_DIR_ITER_BACKWARD=${TRAIN_DIR}-${epoch}-backward
  mkdir -p $TRAIN_DIR_ITER_BACKWARD
  mkdir -p $TRAIN_DIR_ITER_BACKWARD/model
  mkdir -p $TRAIN_DIR_ITER_BACKWARD/corpus
  cp $SRC_TRUE.sample.${Sent}.${epoch}.${SRC} $TRAIN_DIR_ITER_BACKWARD/corpus/$SRC.sample.${Sent}.${epoch}.${SRC}
  cp $SRC_TRUE.sample.${Sent}.${epoch}.${TGT} $TRAIN_DIR_ITER_BACKWARD/corpus/$SRC.sample.${Sent}.${epoch}.${TGT}
  echo "Train Moses Backward"
  
  $TRAIN_MODEL -root-dir $TRAIN_DIR_ITER_BACKWARD -corpus ${TRAIN_DIR_ITER_BACKWARD}/corpus/$SRC.sample.${Sent}.${epoch} \
  -f $TGT -e $SRC -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
  -lm 0:5:$SRC_LM_BLM:8  -external-bin-dir $MOSES_PATH/bin -cores $N_THREADS  -max-phrase-length=4 \
  -mgiza -mgiza-cpus 2 -parallel
 
  
  echo "Removing lexical reordering features ..."
  mv $TRAIN_DIR_ITER_BACKWARD/model/moses.ini $TRAIN_DIR_ITER_BACKWARD/model/moses.ini.bkp
  cat $TRAIN_DIR_ITER_BACKWARD/model/moses.ini.bkp | grep -v LexicalReordering > $TRAIN_DIR_ITER_BACKWARD/model/moses.ini

  

  # Eval: TGT to SRC
  echo "Translating test sentences..."
  $MOSES_BIN -f $TRAIN_DIR_ITER_BACKWARD/model/moses.ini < $TGT_TEST.true > $TRAIN_DIR_ITER_BACKWARD/test.$SRC.hyp.true
  echo "Detruecasing hypothesis..."
  $DETRUECASER < $TRAIN_DIR_ITER_BACKWARD/test.$SRC.hyp.true > $TRAIN_DIR_ITER_BACKWARD/test.$SRC.hyp.tok
  echo "Evaluating translations..."
  $MULTIBLEU $SRC_TEST.true < $TRAIN_DIR_ITER_BACKWARD/test.$SRC.hyp.true > $TRAIN_DIR_ITER_BACKWARD/eval.true.${TGT}2${SRC}
 
  cat $TRAIN_DIR_ITER_BACKWARD/eval.true.${TGT}2${SRC}

  # translate the monolingual data from random sample 50m sentence (TGT to SRC)
  echo "Translating monolingual data..."
  shuf -n ${Sent} $TGT_TRUE > $TGT_TRUE.sample.${Sent}.${epoch}.${TGT}
  $MOSES_BIN -threads $N_THREADS -f $TRAIN_DIR_ITER_BACKWARD/model/moses.ini < $TGT_TRUE.sample.${Sent}.${epoch}.${TGT} > $TGT_TRUE.sample.${Sent}.${epoch}.${SRC}
  # train another model with direction (SRC to TGT)
  epoch_next=$((epoch + 1))
  TRAIN_DIR_ITER_FORWARD=${TRAIN_DIR}-${epoch_next}-forward
  mkdir -p $TRAIN_DIR_ITER_FORWARD
  mkdir -p $TRAIN_DIR_ITER_FORWARD/model
  mkdir -p $TRAIN_DIR_ITER_FORWARD/corpus
  cp $TGT_TRUE.sample.${Sent}.${epoch}.${SRC} $TRAIN_DIR_ITER_FORWARD/corpus/$TGT.sample.${Sent}.${epoch}.${SRC}
  cp $TGT_TRUE.sample.${Sent}.${epoch}.${TGT} $TRAIN_DIR_ITER_FORWARD/corpus/$TGT.sample.${Sent}.${epoch}.${TGT}
  echo "Train Moses Forward"
  $TRAIN_MODEL -root-dir $TRAIN_DIR_ITER_FORWARD -corpus $TRAIN_DIR_ITER_FORWARD/corpus/$TGT.sample.${Sent}.${epoch} \
  -f $SRC -e $TGT -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
  -lm 0:5:$TGT_LM_BLM:8 -external-bin-dir $MOSES_PATH/bin \
  -max-phrase-length=4 -cores $N_THREADS -mgiza -mgiza-cpus 2 -parallel
  
  echo "Removing lexical reordering features ..."
  mv $TRAIN_DIR_ITER_FORWARD/model/moses.ini $TRAIN_DIR_ITER_FORWARD/model/moses.ini.bkp
  cat $TRAIN_DIR_ITER_FORWARD/model/moses.ini.bkp | grep -v LexicalReordering > $TRAIN_DIR_ITER_FORWARD/model/moses.ini

  
  # Eval: SRC to TGT
  echo "Translating test sentences..."
  $MOSES_BIN  -f $TRAIN_DIR_ITER_FORWARD/model/moses.ini < $SRC_TEST.true > $TRAIN_DIR_ITER_FORWARD/test.$TGT.hyp.true
  echo "Detruecasing hypothesis..."
  $DETRUECASER < $TRAIN_DIR_ITER_FORWARD/test.$TGT.hyp.true > $TRAIN_DIR_ITER_FORWARD/test.$TGT.hyp.tok
  echo "Evaluating translations..."
  $MULTIBLEU $TGT_TEST.true < $TRAIN_DIR_ITER_FORWARD/test.$TGT.hyp.true > $TRAIN_DIR_ITER_FORWARD/eval.true.${SRC}2${TGT}
  
  cat $TRAIN_DIR_ITER_FORWARD/eval.true.${SRC}2${TGT}

done

echo "End of training. Experiment is stored in: $TRAIN_DIR"
