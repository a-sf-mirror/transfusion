DO_CC=gcc -Wall

all:
	make bin
	make doc

bin:
	$(DO_CC) -o art2tga art2tga.c
	$(DO_CC) -o tga2art tga2art.c

clean:
	rm -f art2tga tga2art ART-Tools-HOWTO.{txt,html}

doc:
	sgml2txt -f ART-Tools-HOWTO.sgml
	sgml2html -s 0 -T 2 ART-Tools-HOWTO.sgml
