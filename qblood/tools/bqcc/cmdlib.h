// Copyright (C) 1999-2000 Id Software, Inc.
//

// cmdlib.h

#ifndef __CMDLIB__
#define __CMDLIB__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>
#include <time.h>

#if defined(__unix__)
#include <unistd.h>

int filelength (int handle);
int tell (int handle);

#define stricmp strcasecmp
#endif

#ifdef WIN32
#include <conio.h>
#include <io.h> //lseek, close, filelength
#include <direct.h> //mkdir
#endif

#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef enum {false, true} boolean;
typedef unsigned char byte;
#endif


void *GetClearedMemory(size_t size);
void *GetMemory(size_t size);
void FreeMemory(void *ptr);

void Error (char *error, ...);

int SafeOpenWrite (char *filename);
int SafeOpenRead (char *filename);
void SafeRead (int handle, void *buffer, long count);
void SafeWrite (int handle, void *buffer, long count);

long LoadFile (char *filename, void **bufferptr);

short LittleShort (short l);
long LittleLong (long l);
float LittleFloat (float l);


char *COM_Parse (char *data);

extern char com_token[1024];
extern int com_eof;



#endif
