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


#include "cmdlib.h"

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
Error

For abnormal program terminations
=================
*/
void Error (const char *error, ...)
{
	va_list argptr;

	printf ("\n************ ERROR ************\n");

	va_start (argptr,error);
	vprintf (error,argptr);
	va_end (argptr);
	printf ("\n");
	exit (1);
}


/*
=============================================================================

						MEMORY FUNCTIONS

=============================================================================
*/

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


/*
=============================================================================

						LOG FUNCTIONS

=============================================================================
*/

static FILE *logfile;


/*
=================
Log_Open
=================
*/
void Log_Open (char *filename)
{
	if (!filename || !strlen (filename))
	{
		printf("openlog <filename>\n");
		return;
	}

	if (logfile)
	{
		printf ("log file is already opened\n");
		return;
	}

	logfile = fopen (filename, "wb");
	if (!logfile)
	{
		printf ("can't open the log file %s\n", filename);
		return;
	}

	printf ("Opened log %s\n", filename);
}


/*
=================
Loc_Close
=================
*/
void Log_Close (void)
{
	if (!logfile)
		return;

	if (fclose (logfile))
	{
		printf ("can't close log file\n");
		return;
	}

	logfile = NULL;
}


/*
=================
Log_Print
=================
*/
void Log_Print (char *fmt, ...)
{
	va_list ap;

	va_start (ap, fmt);
	vprintf (fmt, ap);
	if (logfile)
	{
		vfprintf (logfile, fmt, ap);
		fflush (logfile);
	}
	va_end (ap);
}


/*
=================
Log_Write
=================
*/
void Log_Write (char *fmt, ...)
{
	va_list ap;

	if (!logfile)
		return;

	va_start (ap, fmt);
	vfprintf (logfile, fmt, ap);
	va_end (ap);
	fflush (logfile);
}


/*
=============================================================================

						FILE FUNCTIONS

=============================================================================
*/

/*
================
FileLength
================
*/
long FileLength (FILE* handle)
{
	long pos;
	long end;

	pos = ftell (handle);
	fseek (handle, 0, SEEK_END);
	end = ftell (handle);
	fseek (handle, pos, SEEK_SET);

	return end;
}


FILE* SafeOpen (const char *filename, const char *mode)
{
	FILE* handle;

	handle = fopen (filename, mode);

	if (handle == NULL)
		Error ("Error opening %s: %s", filename, strerror (errno));

	return handle;
}


FILE* SafeOpenWrite (const char *filename)
{
	return SafeOpen (filename, "wb");
}


FILE* SafeOpenRead (const char *filename)
{
	return SafeOpen (filename, "rb");
}


void SafeRead (FILE* handle, void *buffer, size_t count)
{
	if (fread (buffer, 1, count, handle) != count)
		Error ("File read failure");
}


void SafeWrite (FILE* handle, void *buffer, size_t count)
{
	if (fwrite (buffer, 1, count, handle) != count)
		Error ("File write failure");
}


/*
==============
LoadFile
==============
*/
long LoadFile (char *filename, void **bufferptr)
{
	FILE* handle;
	long length;
	void *buffer;

	handle = SafeOpenRead (filename);
	length = FileLength (handle);
	buffer = GetMemory (length+1);
	((byte *)buffer)[length] = 0;
	SafeRead (handle, buffer, length);
	fclose (handle);

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

#endif
