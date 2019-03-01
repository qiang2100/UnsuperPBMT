from smart_open import smart_open

import json

from nltk import tokenize


output_file = open("wiki_sent.txt", "w")


#def check_upper(c):

    #if c >='A'  and c <

sentId = 1
for line in smart_open('enwiki-latest.json.gz'):
    article = json.loads(line.decode('utf-8'))

    #print("Article title: %s" % article['title'])

    

    for section_title, section_text in zip(article['section_titles'], article['section_texts']):
        #print("Section title: %s" % section_title)
        #print("Section text: %s" % section_text)

        
        big_sents = section_text.splitlines()

        for sents in big_sents:
            if(len(sents)<15):
                continue
            
            sub_sents = tokenize.sent_tokenize(sents)

            for sent in sub_sents:
                #print("----:%s" % sent[0])

                if(len(sent)>300):
                    continue

                if(len(sent)>15 and sent[0].isupper()):

                    if(sentId%10000 == 0):
                        print(sentId)

                    sentId += 1
                    output_file.write(sent + "\n")

        #break
    #break


output_file.close()