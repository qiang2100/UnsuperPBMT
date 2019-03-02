import collections

from collections import OrderedDict

wordcount = collections.Counter()

num = 0

with open("wiki_sent.txt") as file:
	for line in file:
		wordcount.update(line.split())

		
		num += 1
		if(num%10000==0):
			print("the %d sentences is computed!" % num)
			#               break


dd = OrderedDict(sorted(wordcount.items(), key=lambda x:x[1]))


with open("word_frequency.txt",'w') as file:
	for k,v in dd.items():
		if(v<100):
			continue;
		file.write('%s %s'% (k,str(v)))
		file.write('\n')
		print (k,v)
