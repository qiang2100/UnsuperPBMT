
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




