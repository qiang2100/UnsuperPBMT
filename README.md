
## Dependencies

* Python 3
* [NumPy](http://www.numpy.org/)
* [Scipy](https://www.scipy.org/)
* [Nltk](http://www.nltk.org/)
* [textstat](https://pypi.org/project/textstat/)
* [gensim](https://pypi.org/project/gensim/)
* [Moses](http://www.statmt.org/moses/) (clean and tokenize text / train PBSMT model)
* [fastBPE](https://github.com/glample/fastBPE) (generate and apply BPE codes)
* [MUSE](https://github.com/facebookresearch/MUSE) (generate cross-lingual embeddings)


## Prior Work

1. Download corpus from English Wikipeida dump [Here] (https://dumps.wikimedia.org/enwiki/)

2. run: ./split_wiki_normal_simple.sh
   We obtain complex sentence set (wiki_FKScore_hard.en) and simplified sentence set (wiki_FKScore_simple.sen).
   
3. Train word embeddings on wikipeida dataset. Or, download pre-training word embeddings "glove.840B.300d.txt" based on [Global Vectors](https://nlp.stanford.edu/projects/glove/).

4. Count word frequency from Wikipeida. 
   run: python Word_Frequency.py
   The results are saved into "word_frequency.txt'
   

## Learn Phrase Tables
  run: python produce-phrase-table.py
  The results are saved into "phrase-table.en-sen'
  
  
 ## UnsuperPBMT

Running the PBSMT approach requires to have a working version of [Moses](http://www.statmt.org/moses/?n=Moses.Overview). On some systems Moses is not very straightforward to compile, and it is sometimes much simpler to download [the binaries](http://www.statmt.org/moses/?n=moses.releases) directly.

Once you have a working version of Moses, edit the `MOSES_PATH` variable inside the `UnsupervisedPBMT.sh` script to indicate the location of Moses directory. Then, simply run:

./UnsuperPBMT.sh
            
## Evaluation

### Datasets
The *wikismall* and *wikilarge* datasets can be downloaded [here](https://drive.google.com/open?id=0B6-YKFW-MnbOYWxUMTBEZ1FBam8)

8 references *wikilarge* test set can be downloaded here https://github.com/cocoxu/simplification/tree/master/data/turkcorpus

Copyright of the *newsela* dataset belongs to https://newsela.com. Please contact newsela.com to obtain the dataset https://newsela.com/data/

### Metrics

#### BLEU
The evaluation pipeline accompanied in our code released produces single reference BLEU scores. 

To be consistant with previous work, you should use 8 references wikilarge test set (availabel at https://github.com/cocoxu/simplification/tree/master/data/turkcorpus)

Therefore, to get the numbers on wikilarge, you should use scripts that support multi-bleu evalution (e.g., [joshua](https://github.com/cocoxu/simplification/#the-text-simplificaiton-system) or mtevalv13a.pl).

Checkout details for BLEU evaluation of wikilarge [here](https://github.com/XingxingZhang/dress/tree/master/experiments/evaluation/BLEU)

#### FRES
Make sure your FRES is on corpus level.

#### SARI
The evaluation pipeline accompanied in our code released produces sentence-level SARI scores. You can use this simplification system (available [here](https://github.com/cocoxu/simplification/#the-text-simplificaiton-system)) to produce corpus level SARI scores.

Checkout details for SARI evaluation [here](https://github.com/XingxingZhang/dress/tree/master/experiments/evaluation/SARI)


### Results
For WikiLarge test set
SARI = 39.08



