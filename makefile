
crubadan.svg: crubadan.dot
	dot -Tsvg -o crubadan.svg crubadan.dot

crubadan.dot: table.csv nbrjoin.pl families.txt
	cat table.csv | perl nbrjoin.pl > $@

clean:
	rm -f crubadan.svg crubadan.dot
