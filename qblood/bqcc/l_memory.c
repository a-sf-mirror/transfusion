// Copyright (C) 1999-2000 Id Software, Inc.
//

//===========================================================================
//
// Name:         l_memory.c
// Function:     memory management
// Programmer:   Mr Elusive
// Last update:  1997-12-16
// Tab Size:     3
//===========================================================================

#include <malloc.h>
#include "qcc.h"
#include "l_log.h"


/*
=================
GetClearedMemory
=================
*/
void *GetClearedMemory(size_t size)
{
	void *ptr;

	ptr = (void *) malloc(size);
	if (!ptr) Error("out of memory");
	memset(ptr, 0, size);
	return ptr;
} //end of the function GetClearedMemory

/*
=================
GetMemory
=================
*/
void *GetMemory(size_t size)
{
	void *ptr;
	ptr = malloc(size);
	if (!ptr)
		Error("out of memory");
	return ptr;
} //end of the function GetMemory

/*
=================
FreeMemory
=================
*/
void FreeMemory(void *ptr)
{
	free(ptr);
} //end of the function FreeMemory
