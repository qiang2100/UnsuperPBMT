#import gensim.downloader as api

import numpy as np

import scipy.spatial as sp

PHRASE_PATTERN = '{src_phrase} ||| {tgt_phrase} ||| {scores} ||| {alignment} ||| {counts} ||| |||'

max_vocab = 50000
#from gensim.scripts.glove2word2vec import glove2word2vec

#from gensim.models import KeyedVectors

#glove_input_file = '/media/qiang/ee63f41d-4004-44fe-bcfd-522df9f2eee8/glove.840B.300d.txt'
#word2vec_output_file = 'glove.840B.300d.txt.word2vec'
#glove2word2vec(glove_input_file, word2vec_output_file)



# load the Stanford GloVe model
#filename = 'glove.6B.100d.txt.word2vec'
#model = KeyedVectors.load_word2vec_format(word2vec_output_file, binary=False)
# calculate: (king - man) + woman = ?
#result = model.most_similar(positive=['woman', 'king'], negative=['man'], topn=1)
#print(result)

#result = model.similar_by_word("cat",20)

#print(result)

def getWordCount(word_count_path):
	word2count = {}
	with open(word_count_path, 'r') as f:
		lines = f.readlines()
		N = 0
		for i in lines:
			i=i.strip()
			if(len(i) > 0):
				i=i.split()
				if(len(i) == 2):
					word2count[i[0]] = float(i[1])
				else:
					print(i)
	    
	return word2count

def getSimilarWords(wordId, sis_vector, num):
	scores_sort_index = np.argsort(-sis_vector)

	if(scores_sort_index[0]!=wordId):
		print("Wrong!")
		return

	most_sim = []

	for i in range(0,num):
		most_sim.append(sis_vector[scores_sort_index[i]])

	return (scores_sort_index[0:num],most_sim)


# read embeddings
print("Loading embeddings ...")
#dico, emb = getWordmap("/media/qiang/ee63f41d-4004-44fe-bcfd-522df9f2eee8/wikipedia/fastText/new.fasttext.vec")
#dico, emb = getWordmap("/media/qiang/ee63f41d-4004-44fe-bcfd-522df9f2eee8/glove.840B.300d.txt")

wordVecPath = "/media/qiang/ee63f41d-4004-44fe-bcfd-522df9f2eee8/glove.840B.300d.txt"

phrase_table_path = "phrase-table.en-sen"

dico=[]
emb = []
f = open(wordVecPath,'r')
lines = f.readlines()

otherWordNum = 0

#SpecialUpper = 0
with open(phrase_table_path, 'w', encoding='utf-8') as ff:
	for (n,line) in enumerate(lines):
		if (n == 0) :
			print(line)
			#continue
		word, vect = line.rstrip().split(' ', 1)

		r = 1
		d = 1
		if( word[0].isupper()):
			phrase_scores = '%e %e' % (r, d)
			ff.write(PHRASE_PATTERN.format(src_phrase=word, tgt_phrase=word,scores=phrase_scores,alignment='',counts='',))
			ff.write('\n')
			#SpecialUpper += 1
			continue
		                
		
		if(otherWordNum<max_vocab):
			vect = np.fromstring(vect, sep=' ')
			emb.append(vect)
			dico.append(word)
		otherWordNum += 1




			
f.close()       

n_src = len(emb)

print("Loaded %i  embeddings." % n_src)

#sis_mat = []

print("computing similar matrix ....")

sis_mat = 1 - sp.distance.cdist(emb, emb, 'cosine')

#sis_mat = get_translations(emb, emb,10000)		


print('finish similar matrix')

word = 'gigantic'

wordId = dico.index('gigantic')

num = 200

most_id, most_score = getSimilarWords(wordId, sis_mat[wordId], num)


for i in range(num):
	print("word=%s score=%f"% (dico[most_id[i]],most_score[i]))






word_count_path = "word_frequency.txt"

word_count = getWordCount(word_count_path)

print("finishing reading word_frequency file")

with open(phrase_table_path, 'a+', encoding='utf-8') as ff:

	ind = 0
	for wordId in range(max_vocab):
		#srcId = dico[wordId]
		word = dico[wordId]
		
		if (not word in word_count):
			wordFre = 100
		else:
			wordFre = word_count[word]

		#if(wordId==2000):
		#	break

		r = 1
		if( wordId<200 or word.isnumeric() or len(word)<6 ):
			phrase_scores = '%e %e' % (r, r)
			ff.write(PHRASE_PATTERN.format(src_phrase=word, tgt_phrase=word,scores=phrase_scores,alignment='',counts='',))
			ff.write('\n')
			continue


		#print('here')
		most_id, most_score = getSimilarWords(wordId, sis_mat[wordId], num)
		#print('here')


		for synId in most_id:

			syn = dico[synId]

			if (not syn in word_count):
				synFre = wordFre
			else:
				synFre = word_count[syn]

			if syn in dico:

				tgtId= dico.index(syn)

				#if(sis_mat[wordId][tgtId]<0.5):
				#	continue

				weight = synFre/(wordFre)

				r = weight * sis_mat[wordId][tgtId]

				if(r>1):
					r = 1
				phrase_scores = '%e %e' % (r, r)
				ff.write(PHRASE_PATTERN.format(src_phrase=word, tgt_phrase=syn,scores=phrase_scores,alignment='',counts='',))
				ff.write('\n')

		if (wordId%1000==0):
			print("the %d word is computed!" % wordId)




