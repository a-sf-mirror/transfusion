// Copyright (C) 1999-2000 Id Software, Inc.
//

//===========================================================================
//
// Name:         l_memory.h
// Function:     memory management
// Programmer:   Mr Elusive
// Last update:  1997-12-16
// Tab Size:     3
//===========================================================================

void *GetClearedMemory(size_t size);
void *GetMemory(size_t size);
void FreeMemory(void *ptr);
