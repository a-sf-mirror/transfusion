# for Solaris
CFLAGS = -g -O2 -Wall -x objective-c

EXES = bqcc

all: $(EXES)

install:
	make app
	cp $(EXES) /LocalApps

app:
	make "CFLAGS = -O4 -g -Wall -arch i386 -arch hppa"

debug:
	make "CFLAGS = -g -Wall"

profile:
	make "CFLAGS = -pg -Wall"

clean:
	rm -f *.o *~ $(EXES)

.c.o: ; gcc -c $(CFLAGS) -o $@ $*.c

QCCFILES = qcc.o pr_lex.o pr_comp.o cmdlib.o l_log.o l_memory.o l_script.o l_precomp.o
bqcc : $(QCCFILES)
        gcc -o bqcc $(QCCFILES)
