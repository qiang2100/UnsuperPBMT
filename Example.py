from readability_score.calculators.fleschkincaid import *
import textstat
import io
import numpy as np
#from readability_score.calculators.dalechall import *

#fk = FleschKincaid(test_data, locale='nl_NL')
#print(fk.us_grade)


input_file = "./wiki_sent.txt"

scores=[]
sentences = []

saveSentNum = 0

with io.open(input_file, 'r', encoding='utf-8', newline='\n', errors='ignore') as f:
	for i, line in enumerate(f):
		
		if(i%10000==0):
			print("the %d sentences is computed!" % i)

		line = line.strip()

		if(line[0].islower()):
			#print(line)
			continue

		if(line[len(line)-1]!='.'):
			#print("not ",line[len(line)-1])
			continue;

		score = textstat.flesch_reading_ease(line)

		if(score< 10 or score>100):
			continue


		sentences.append(line)

		scores.append(score)

		saveSentNum += 1

		#if(saveSentNum==2000000):
			#break		
		
#print(scores)

scores = np.array(scores)

scores_sort_index = np.argsort(scores)

#print(scores_sort_index)

#scores_sort = np.zeros(len(scores_sort_index),dtype=int)

output_score_hardfile = open("wiki_FKScore_hard.en", "w")

total_num = len(scores_sort_index)
#output_file = open("OutputSentences.txt", "w")
for i in range(0, total_num):
	#scores_sort[i] = scores[scores_sort_index[i]]
	line = sentences[scores_sort_index[i]];
	words = line.split(' ')
	if(len(words)>25):
		continue
	output_score_hardfile.write(line)
	output_score_hardfile.write('\n')
	#output_file.write()

	if(i==10000000):
		break


output_score_simplefile = open("wiki_FKScore_simple.sen", "w")
#output_file = open("OutputSentences.txt", "w")
for i in range(total_num-1,0,-1):
	#scores_sort[i] = scores[scores_sort_index[i]]
	line = sentences[scores_sort_index[i]];
	words = line.split(' ')
	if(len(words)<10):
		continue

	output_score_simplefile.write(line)
	output_score_simplefile.write('\n')
	#output_file.write()

	if((total_num-i)==10000000):
		break




