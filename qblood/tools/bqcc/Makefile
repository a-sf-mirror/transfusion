CFLAGS = -g -O6 -Wall -Werror
CC = gcc
EXE = bqcc
OBJECTS = cmdlib.o \
          l_log.o \
          l_precomp.o \
          l_script.o \
          pr_comp.o \
          pr_lex.o \
          qcc.o

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $*.c

$(EXE) : $(OBJECTS)
	$(CC) -o $(EXE) $(OBJECTS)

clean:
	rm -f *.o *~ $(EXE)
