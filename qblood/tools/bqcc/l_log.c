// Copyright (C) 1999-2000 Id Software, Inc.
//

//===========================================================================
//
// Name:         l_log.c
// Function:     log file
// Programmer:   Mr Elusive
// Last update:  1997-12-16
// Tab Size:     3
//===========================================================================

#include "qcc.h"

int verbose = true;

#define MAX_LOGFILENAMESIZE		1024

typedef struct logfile_s
{
	char filename[MAX_LOGFILENAMESIZE];
	FILE *fp;
	int numwrites;
} logfile_t;

logfile_t logfile;

/*
=================
Log_Open
=================
*/
void Log_Open(char *filename)
{
	if (!filename || !strlen(filename))
	{
		printf("openlog <filename>\n");
		return;
	} //end if
	if (logfile.fp)
	{
		printf("log file %s is already opened\n", logfile.filename);
		return;
	} //end if
	logfile.fp = fopen(filename, "wb");
	if (!logfile.fp)
	{
		printf("can't open the log file %s\n", filename);
		return;
	} //end if
	strncpy(logfile.filename, filename, MAX_LOGFILENAMESIZE);
	printf("Opened log %s\n", logfile.filename);
} //end of the function Log_Create

/*
=================
Loc_Close
=================
*/
void Log_Close(void)
{
	if (!logfile.fp)
	{
		printf("no log file to close\n");
		return;
	} //end if
	if (fclose(logfile.fp))
	{
		printf("can't close log file %s\n", logfile.filename);
		return;
	} //end if
	logfile.fp = NULL;
	printf("Closed log %s\n", logfile.filename);
} //end of the function Log_Close

/*
=================
Log_Shutdown
=================
*/
void Log_Shutdown(void)
{
	if (logfile.fp) Log_Close();
} //end of the function Log_Shutdown

/*
=================
Log_Print
=================
*/
void Log_Print(char *fmt, ...)
{
	va_list ap;

	if (verbose)
	{
		va_start(ap, fmt);
		vprintf(fmt, ap);
		va_end(ap);
	} //end if

	va_start(ap, fmt);
	if (logfile.fp)
	{
		vfprintf(logfile.fp, fmt, ap);
		fflush(logfile.fp);
	} //end if
	va_end(ap);
} //end of the function Log_Print

/*
=================
Log_Write
=================
*/
void Log_Write(char *fmt, ...)
{
	va_list ap;

	if (!logfile.fp) return;
	va_start(ap, fmt);
	vfprintf(logfile.fp, fmt, ap);
	va_end(ap);
	fflush(logfile.fp);
} //end of the function Log_Write

/*
=================
Log_WriteTimeStamped
=================
*/
void Log_WriteTimeStamped(char *fmt, ...)
{
	va_list ap;

	if (!logfile.fp) return;
/*	fprintf(logfile.fp, "%d   %02d:%02d:%02d:%02d   ",
					logfile.numwrites,
					(int) (botlibglobals.time / 60 / 60),
					(int) (botlibglobals.time / 60),
					(int) (botlibglobals.time),
					(int) ((int) (botlibglobals.time * 100)) -
							((int) botlibglobals.time) * 100);*/
	va_start(ap, fmt);
	vfprintf(logfile.fp, fmt, ap);
	va_end(ap);
	logfile.numwrites++;
	fflush(logfile.fp);
} //end of the function Log_Write

/*
=================
Log_FileStruct
=================
*/
FILE *Log_FileStruct(void)
{
	return logfile.fp;
} //end of the function Log_FileStruct

/*
=================
Log_Flush
=================
*/
void Log_Flush(void)
{
	if (logfile.fp) fflush(logfile.fp);
} //end of the function Log_Flush
