
crubadan.svg: crubadan.dot
	dot -Tsvg -o $@ crubadan.dot

crubadan-neato.svg: crubadan.dot
	neato -Gstart=rand -Tsvg -o $@ crubadan.dot

crubadan.dot: table.csv nbrjoin.pl langs.txt colors.txt
	cat table.csv | perl nbrjoin.pl > $@

clean:
	rm -f crubadan.svg crubadan.dot
