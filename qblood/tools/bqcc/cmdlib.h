/*
    Copyright (C) 1999-2000  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


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

#ifdef __unix__
# include <unistd.h>
# define stricmp strcasecmp
#elif defined(WIN32)
# include <conio.h>
# include <direct.h>
# include <io.h>
#endif


#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef enum {false, true} boolean;
typedef unsigned char byte;
#endif

char *COM_Parse (char *data);

void Error (const char *error, ...);

void *GetClearedMemory(size_t size);
void *GetMemory(size_t size);
void FreeMemory(void *ptr);

void Log_Open (char *filename);
void Log_Close (void);
void Log_Print (char *fmt, ...);
void Log_Write (char *fmt, ...);

long FileLength (FILE* handle);
FILE* SafeOpenWrite (const char *filename);
FILE* SafeOpenRead (const char *filename);
void SafeRead (FILE* handle, void *buffer, size_t count);
void SafeWrite (FILE* handle, void *buffer, size_t count);
long LoadFile (const char *filename, void **bufferptr);

extern char com_token[1024];
extern int com_eof;


#ifdef __BIG_ENDIAN__

short LittleShort (short l);
long LittleLong (long l);
float LittleFloat (float l);

#else
# define LittleShort(l) (l)
# define LittleLong(l) (l)
# define LittleFloat(l) (l)
#endif


#endif  // #ifndef __CMDLIB__
