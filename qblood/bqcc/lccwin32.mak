# Makefile for LCC-Win32

CC=lcc
OBJS= qcc.obj pr_lex.obj pr_comp.obj cmdlib.obj l_log.obj l_memory.obj l_script.obj l_precomp.obj \

all:	bqcc.exe

bqcc.exe:    $(OBJS)
	lcclnk *.obj -o bqcc.exe

clean:
	del *.obj bqcc.exe

%.obj: %.c
	$(CC) $(CFLAGS) $<

