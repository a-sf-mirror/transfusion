// Copyright (C) 1999-2000 Id Software, Inc.
//

// cmdlib.c

#include "cmdlib.h"

#define PATHSEPERATOR   '/'

char com_token[1024];
int com_eof;


/*
==============
COM_Parse

Parse a token out of a string
==============
*/
char *COM_Parse (char *data)
{
	int c;
	int len;

	len = 0;
	com_token[0] = 0;

	if (!data)
		return NULL;

// skip whitespace
skipwhite:
	while ( (c = *data) <= ' ')
	{
		if (c == 0)
		{
			com_eof = true;
			return NULL;  // end of file;
		}
		data++;
	}

// skip // comments
	if (c=='/' && data[1] == '/')
	{
		while (*data && *data != '\n')
			data++;
		goto skipwhite;
	}


// handle quoted strings specially
	if (c == '\"')
	{
		data++;
		do
		{
			c = *data++;
			if (c=='\"')
			{
				com_token[len] = 0;
				return data;
			}
			com_token[len] = c;
			len++;
		} while (1);
	}

// parse single characters
	if (c=='{' || c=='}'|| c==')'|| c=='(' || c=='\'' || c==':')
	{
		com_token[len] = c;
		len++;
		com_token[len] = 0;
		return data+1;
	}

// parse a regular word
	do
	{
		com_token[len] = c;
		data++;
		len++;
		c = *data;
	if (c=='{' || c=='}'|| c==')'|| c=='(' || c=='\'' || c==':')
			break;
	} while (c>32);

	com_token[len] = 0;
	return data;
}


/*
=================
GetClearedMemory
=================
*/
void* GetClearedMemory (size_t size)
{
	void* ptr;

	ptr = GetMemory (size);
	memset (ptr, 0, size);

	return ptr;
}


/*
=================
GetMemory
=================
*/
void* GetMemory (size_t size)
{
	void* ptr;

	ptr = malloc (size);
	if (ptr == NULL)
		Error ("Malloc failure for %lu bytes", size);

	return ptr;
}


/*
=================
FreeMemory
=================
*/
void FreeMemory (void *ptr)
{
	free (ptr);
}


#if defined(__unix__)
/*
================
filelength
================
*/
int filelength (int handle)
{
	int pos;
	int end;

	pos = tell(handle);
	lseek(handle, 0, SEEK_END);
	end = tell(handle);
	lseek(handle, pos, SEEK_SET);

	return end;
}

int tell (int handle)
{
	return lseek (handle, 0, SEEK_CUR);
}
#endif  // #if defined(__unix__)


/*
=============================================================================

						MISC FUNCTIONS

=============================================================================
*/

/*
=================
Error

For abnormal program terminations
=================
*/
void Error (char *error, ...)
{
	va_list argptr;

	printf ("\n************ ERROR ************\n");

	va_start (argptr,error);
	vprintf (error,argptr);
	va_end (argptr);
	printf ("\n");
	exit (1);
}


#ifndef O_BINARY
#define O_BINARY 0
#endif

int SafeOpenWrite (char *filename)
{
	int handle;

	handle = open(filename,O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, 0666);

	if (handle == -1)
		Error ("Error opening %s: %s",filename,strerror(errno));

	return handle;
}

int SafeOpenRead (char *filename)
{
	int handle;

	handle = open(filename,O_RDONLY | O_BINARY);

	if (handle == -1)
		Error ("Error opening %s: %s",filename,strerror(errno));

	return handle;
}


void SafeRead (int handle, void *buffer, long count)
{
	if (read (handle,buffer,count) != count)
		Error ("File read failure");
}


void SafeWrite (int handle, void *buffer, long count)
{
	if (write (handle,buffer,count) != count)
		Error ("File write failure");
}


/*
==============
LoadFile
==============
*/
long LoadFile (char *filename, void **bufferptr)
{
	int handle;
	long length;
	void *buffer;

	handle = SafeOpenRead (filename);
	length = filelength (handle);
	buffer = GetMemory (length+1);
	((byte *)buffer)[length] = 0;
	SafeRead (handle, buffer, length);
	close (handle);

	*bufferptr = buffer;
	return length;
}


/*
============================================================================

					BYTE ORDER FUNCTIONS

============================================================================
*/

#ifdef __BIG_ENDIAN__

short LittleShort (short l)
{
	byte b1,b2;

	b1 = l&255;
	b2 = (l>>8)&255;

	return (b1<<8) + b2;
}


long LittleLong (long l)
{
	byte b1,b2,b3,b4;

	b1 = l&255;
	b2 = (l>>8)&255;
	b3 = (l>>16)&255;
	b4 = (l>>24)&255;

	return ((long)b1<<24) + ((long)b2<<16) + ((long)b3<<8) + b4;
}


float LittleFloat (float l)
{
	union {byte b[4]; float f;} in, out;

	in.f = l;
	out.b[0] = in.b[3];
	out.b[1] = in.b[2];
	out.b[2] = in.b[1];
	out.b[3] = in.b[0];

	return out.f;
}


#else


short LittleShort (short l)
{
	return l;
}

long LittleLong (long l)
{
	return l;
}

float LittleFloat (float l)
{
	return l;
}


#endif
