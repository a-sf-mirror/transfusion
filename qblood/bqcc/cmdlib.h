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
//#include <sys/file.h>
#include <fcntl.h>
#include <stdarg.h>
#include <time.h>

#if defined(UNIX) || defined(unix)
#include <unistd.h>
#define stricmp strcasecmp
#define strcmpi strcasecmp
#endif

#if defined(WIN32)|defined(_WIN32)|defined(__NT__)|defined(__WINDOWS__)|defined(__WINDOWS_386__)
#include <conio.h>
#include <io.h> //lseek, close, filelength
#include <direct.h> //mkdir
#endif

#ifdef NeXT
#include <libc.h>
#endif

#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef enum {false, true} boolean;
typedef unsigned char byte;
#endif

// the dec offsetof macro doesn't work very well...
#define myoffsetof(type,identifier) ((size_t)&((type *)0)->identifier)


// set these before calling CheckParm
extern int myargc;
extern char **myargv;

char *strupr (char *in);
char *strlower (char *in);
/* MrE:   can't use these prototypes, they are inconsistant with
               prototypes in original header files
int filelength (int handle);
int tell (int handle);
*/

double I_FloatTime (void);

void  Error (char *error, ...);
int      CheckParm (char *check);

int   SafeOpenWrite (char *filename);
int   SafeOpenRead (char *filename);
void  SafeRead (int handle, void *buffer, long count);
void  SafeWrite (int handle, void *buffer, long count);
void  *SafeMalloc (long size);

long  LoadFile (char *filename, void **bufferptr);
void  SaveFile (char *filename, void *buffer, long count);

void  DefaultExtension (char *path, char *extension);
void  DefaultPath (char *path, char *basepath);
void  StripFilename (char *path);
void  StripExtension (char *path);

void  ExtractFilePath (char *path, char *dest);
void  ExtractFileBase (char *path, char *dest);
void  ExtractFileExtension (char *path, char *dest);

long  ParseNum (char *str);

short BigShort (short l);
short LittleShort (short l);
long  BigLong (long l);
long  LittleLong (long l);
float BigFloat (float l);
float LittleFloat (float l);


char *COM_Parse (char *data);

extern   char  com_token[1024];
extern   int      com_eof;



#endif
