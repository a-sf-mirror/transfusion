//
// rff.c
//
// Read and extract the contents of a RFF file
//

/* Copyright (C) 2001-2010  Mathieu Olivier
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


// Many thanks to Matt Saettler <matts@saettler.com> for his explanations.
// You can find his website at "http://www.saettler.com/".


#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


/* --------------------------------- */
/* --- Plateform dependent stuff --- */
/* --------------------------------- */

// Win32
#ifdef WIN32
    #include <windows.h>
    #define StrCaseCmp stricmp

// Linux
#elif defined (linux) || defined (__linux__)
    #define StrCaseCmp strcasecmp

#else
    #error "Unsupported operating system"
#endif


/* ----------------- */
/* --- Constants --- */
/* ----------------- */

// Current version of this software
#define VERSION "0.2"

// Default size of Buffer in Kb
#define DEFAULT_BUFFER_SIZE 4

// File flags
enum
{
    FLAG_NONE      = 0,
    FLAG_ENCRYPTED = (1 << 4)  // 0x10
};


/* ------------- */
/* --- Types --- */
/* ------------- */

// Boolean
#ifndef __cplusplus  // Standard C++ has already this "bool"
    typedef enum { false, true } bool;
#endif

// Definition of some basic types
// Useful, because sometime we need to be sure of the size of an integer type
// May need to be "#ifdef"ed to fit a particular OS on a particular processor
typedef   signed char  int8;
typedef   signed short int16;
typedef   signed int   int32;
typedef unsigned char  uint8;
typedef unsigned short uint16;
typedef unsigned int   uint32;

// Command
typedef enum
{
    CMD_LIST,
    CMD_EXTRACT
} Command_t;

// RFF header
typedef struct
{
    uint8  Magic [4];
    uint16 Version;
    uint16 Unknown0;
    uint32 DirOffset;
    uint32 DirNbEntries;
    uint32 Unknown1;
    uint32 Unknown2;
    uint32 Unknown3;
    uint32 Unknown4;
} RffHeader_t;

// Encryption modes
typedef enum
{
    ENCRYPT_NONE,  // RFF 2.0
    ENCRYPT_3_0,   // RFF 3.0
    ENCRYPT_3_1,   // RFF 3.1
} Encryption_t;

// Directory entry for a file
typedef struct
{
    uint8  Unknown0 [16];
    uint32 Offset;
    uint32 Size;
    uint32 Unknown1;
    uint32 Time;           // Obtained with the "time" standard function
    uint8  Flags;
    char   Name [11];
    uint32 Unknown2;       // ID ? Maybe for an enumeration function...
} DirectoryEntry_t;

// Informations about a packed file
typedef struct
{
    char   Name [13];
    uint8  Flags;
    uint32 Time;
    uint32 Size;
    uint32 Offset;
} FileInfos_t;


/* ------------------------ */
/* --- Global variables --- */
/* ------------------------ */

// The RFF file
static FILE* RffFile = NULL;

// Number of files in the RFF file
static uint32 NbFiles = 0;

// Array of informations about the packed files
static FileInfos_t* FileInfos = NULL;

// All purpose buffer (so we don't have to "malloc" one each time we need some storage)
static uint8* Buffer;
static uint32 BufferSize = DEFAULT_BUFFER_SIZE * 1024;

// Command
static Command_t Command;

// Options
static bool Opt_Verbose         = false;
static bool Opt_ExtractAllFiles = false;

// Is the file encrypted ?
static Encryption_t EncryptionMode = ENCRYPT_3_1;


/* ----------------- */
/* --- Functions --- */
/* ----------------- */

/* ------ Prototypes ------ */

// Extract files which match "MatchName"
static bool ExtractFile (const char* MatchName);

// Load informations about the contents of the RFF file
static bool LoadRffInformations (void);

// Parse the program arguments
//     Returns the index of RFF file name in ArgV, or -1 in error
static int ParseArg (int ArgC, const char* ArgV []);

// Print only if VerboseOption is true
//     Returns the number of written characters, or -1 if error
static int VerbosePrintf (const char* Format, ...);


/* ------ Implementations ------ */

/*
====================
ExtractFile

Extract files which match "MatchName"
====================
*/
static bool ExtractFile (const char* MatchName)
{
    // Variables
    uint32 NbReadBytes;
    uint32 NbRequestedBytes;
    uint32 NbRemainBytes;
    uint32 Ind;
    uint32 FileInfosIndex;
    FILE* ExtractedFile;

    // Find the file index
    for (FileInfosIndex = 0; FileInfosIndex < NbFiles; FileInfosIndex++)
        if (StrCaseCmp (MatchName, FileInfos[FileInfosIndex].Name) == 0)
            break;
    if (FileInfosIndex == NbFiles)
    {
        printf ("Error: can't find file \"%s\"\n", MatchName);
        return false;
    }

    printf ("Extracting \"%s\"...", FileInfos[FileInfosIndex].Name);

    // Go to the start of the file
    if (fseek (RffFile, FileInfos[FileInfosIndex].Offset, SEEK_SET) != 0)
    {
        printf ("\nError: can't go to the offset %u\n", FileInfos[FileInfosIndex].Offset);
        return false;
    }

    // Extract the first part
    NbRemainBytes = FileInfos[FileInfosIndex].Size;
    NbRequestedBytes = (NbRemainBytes > BufferSize) ?  BufferSize : NbRemainBytes;
    NbReadBytes = fread (Buffer, 1, NbRequestedBytes, RffFile);
    if (NbReadBytes != NbRequestedBytes)
    {
        printf ("\nError: can't extract enough bytes from the RFF file\n");
        return false;
    }
    NbRemainBytes -= NbReadBytes;

    // Open the new file
    ExtractedFile = fopen (FileInfos[FileInfosIndex].Name, "wb");
    if (ExtractedFile == NULL)
    {
        printf ("\nError: can't create the new file \"%s\"\n", FileInfos[FileInfosIndex].Name);
        return false;
    }

    // Decrypt the first bytes if they're encrypted (256 bytes max)
    if (EncryptionMode != ENCRYPT_NONE && (FileInfos[FileInfosIndex].Flags & FLAG_ENCRYPTED) != 0)
        for (Ind = 0; Ind < ((NbReadBytes > 256) ? 256 : NbReadBytes); Ind++)
            Buffer[Ind] ^= (Ind >> 1);

    // Copy its contents into the new file
    fwrite (Buffer, 1, NbReadBytes, ExtractedFile);

    // While there is bytes remaining in the file
    while (NbRemainBytes != 0)
    {
        // Load the next bytes
        NbRequestedBytes = (NbRemainBytes > BufferSize) ?  BufferSize : NbRemainBytes;
        NbReadBytes = fread (Buffer, 1, NbRequestedBytes, RffFile);
        if (NbReadBytes != NbRequestedBytes)
        {
            printf ("\nError: can't extract enough bytes from the RFF file to %s\n", FileInfos[FileInfosIndex].Name);
            fclose (ExtractedFile);
            return false;
        }
        NbRemainBytes -= NbReadBytes;

        // Copy its contents into the new file
        fwrite (Buffer, 1, NbReadBytes, ExtractedFile);
    }

    printf (" done\n");

    fclose (ExtractedFile);
    return true;
}


/*
====================
LoadRffInformations

Load informations about the contents of the RFF file
====================
*/
static bool LoadRffInformations (void)
{
    // Variables
    uint8* Directory;
    uint32 NbReadBytes;
    RffHeader_t RffHeader;
    DirectoryEntry_t* DirectoryEntry;
    uint32 Ind, Ind2;
    char FileName [9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    char FileExtension [4] = {0, 0, 0, 0};

    // Read the header
    NbReadBytes = fread (&RffHeader, 1, sizeof (RffHeader), RffFile);
    if (NbReadBytes != sizeof (RffHeader))
    {
        printf ("Error: RFF file is too short to be valid\n");
        return false;
    }

    // Check the magic number
    if (RffHeader.Magic[0] != 'R'  ||
        RffHeader.Magic[1] != 'F'  ||
        RffHeader.Magic[2] != 'F'  ||
        RffHeader.Magic[3] != 0x1A )
    {
        printf ("Error: this file is not a RFF file\n");
        return false;
    }

    // Check the version and set the encryption mode
    switch (RffHeader.Version)
    {
        case 0x200:
            EncryptionMode = ENCRYPT_NONE;
            break;

        case 0x300:
            EncryptionMode = ENCRYPT_3_0;
            break;

        case 0x301:
            EncryptionMode = ENCRYPT_3_1;
            break;

        default:
            printf ("Error: unsupported RFF format (%hu.%hu)\n"
                    "       Please, upgrade your Blood copy\n"
                    , RffHeader.Version >> 8
                    , RffHeader.Version & 0xFF);
            return false;
    }

    if (Command == CMD_LIST)
        VerbosePrintf ("====== Header ======\n"
                       "Magic: 0x%02X.%02X.%02X.%02X\n"
                       "Version: %u.%u\n"
                       "Unknown0: %hu\n"
                       "DirOffset: %u\n"
                       "DirNbEntries: %u\n"
                       "Unknown1: %u / Unknown2: %u\n"
                       "Unknown3: %u / Unknown4: %u\n\n"
                       , RffHeader.Magic[0], RffHeader.Magic[1], RffHeader.Magic[2], RffHeader.Magic[3]
                       , (RffHeader.Version >> 8) & 0xFF, RffHeader.Version & 0xFF
                       , RffHeader.Unknown0
                       , RffHeader.DirOffset
                       , RffHeader.DirNbEntries
                       , RffHeader.Unknown1, RffHeader.Unknown2
                       , RffHeader.Unknown3, RffHeader.Unknown4);

    printf ("%u file(s) found\n\n", RffHeader.DirNbEntries);
    NbFiles = RffHeader.DirNbEntries;

    // Read the directory
    fseek (RffFile, RffHeader.DirOffset, SEEK_SET);
    Directory = malloc (RffHeader.DirNbEntries * sizeof (DirectoryEntry_t));
    if (Directory == NULL)
    {
        printf ("Error: Not enough memory to load the directory\n");
        return false;
    }
    NbReadBytes = fread (Directory, 1, RffHeader.DirNbEntries * sizeof (DirectoryEntry_t), RffFile);
    if (NbReadBytes != RffHeader.DirNbEntries * sizeof (DirectoryEntry_t))
    {
        printf ("Error: can't read the whole dictionary (%d bytes read instead of %u)",
                NbReadBytes, RffHeader.DirNbEntries * sizeof (DirectoryEntry_t));
        free (Directory);
        return false;
    }

    // Decrypt the directory (depend on the version)
    if (EncryptionMode != ENCRYPT_NONE)
    {
        uint32 CryptoKey;

        if (EncryptionMode == ENCRYPT_3_0)
            CryptoKey = RffHeader.DirOffset;
        else
            CryptoKey = (RffHeader.DirOffset << 1);

        for (Ind = 0; Ind < RffHeader.DirNbEntries * sizeof (DirectoryEntry_t); Ind++)
        {
            Directory[Ind] ^= (CryptoKey >> 1);
            CryptoKey++;
        }
    }

    // Allocate "FileInfos"
    FileInfos = malloc (RffHeader.DirNbEntries * sizeof (FileInfos_t));
    if (FileInfos == NULL)
    {
        printf ("Error: Not enough memory to store the directory\n");
        free (Directory);
        return false;
    }

    // Print the directory informations and store them in "FileInfos"
    DirectoryEntry = (DirectoryEntry_t*)Directory;
    for (Ind = 0; Ind < RffHeader.DirNbEntries; Ind++)
    {
        // Extract the file name
        strncpy (FileExtension, DirectoryEntry->Name,     3);
        strncpy (FileName,      &DirectoryEntry->Name[3], 8);

        // If we must print the file list
        if (Command == CMD_LIST)
        {
            printf (" * %s.%s\t(size: %u bytes)\n", FileName, FileExtension, DirectoryEntry->Size);
            VerbosePrintf ("\tOffset: %u\n"
                           "\tTime:   %s"
                           "\tFlags:  0x%02X\n"
                           "\t--- Unknown fields ---\n"
                           "\tUnknown1:        0x%08X\n"
                           "\tUnknown2 (ID ?): 0x%08X\n"
                           "\tUnknown0:        0x"
                           , DirectoryEntry->Offset
                           , ctime ((const long*)&DirectoryEntry->Time)
                           , DirectoryEntry->Flags
                           , DirectoryEntry->Unknown1
                           , DirectoryEntry->Unknown2
                          );
            for (Ind2 = 0; Ind2 < 16; Ind2++)
                VerbosePrintf ("%02X", DirectoryEntry->Unknown0[Ind2]);
            VerbosePrintf ("\n\n");
        }

        sprintf (FileInfos[Ind].Name, "%s.%s", FileName, FileExtension);
        FileInfos[Ind].Offset = DirectoryEntry->Offset;
        FileInfos[Ind].Size   = DirectoryEntry->Size;
        FileInfos[Ind].Flags  = DirectoryEntry->Flags;
        FileInfos[Ind].Time   = DirectoryEntry->Time;

        DirectoryEntry++;
    }

    free (Directory);
    return true;
}


/*
====================
main

Main procedure
====================
*/
int main (int ArgC, char* ArgV [])
{
    // Variables
    int Ind;

    // Header
    printf ("\n"
            "RFF version " VERSION " by Mathieu Olivier\n"
            "==================================\n\n");

    // Check arguments
    Ind = ParseArg (ArgC, (const char**)ArgV);
    if (Ind == -1)
    {
        printf ("Syntax: rff <command> [options] <RFF file> [files ...]\n"
                "   Command:\n"
                "      'l': Print the list of files which are packed in the RFF file\n"
                "      'x': Extract files (doesn't support jokers characters: '*' and '?')\n"
                "\n"
                "   Options:\n"
                "      '-a': Extract ALL files\n"
                "      '-b<buffer size>': Extraction buffer size in Kb (default: %u Kb)\n"
                "      '-v': Verbose mode\n"
                "\n",
                DEFAULT_BUFFER_SIZE
               );
        return EXIT_FAILURE;
    }

    // Open the file
    RffFile = fopen (ArgV[Ind], "rb");
    if (RffFile == NULL)
    {
        printf ("Error: can't open \"%s\"\n", ArgV[Ind]);
        return EXIT_FAILURE;
    }

    // Load RFF informations
    if (! LoadRffInformations ())
    {
        fclose (RffFile);
        return EXIT_FAILURE;
    }

    // If we want to extract files
    if (Command == CMD_EXTRACT)
    {
        // Allocate Buffer
        VerbosePrintf ("Allocating the extraction buffer (%u Kb)\n\n", BufferSize);
        Buffer = malloc (BufferSize);
        if (Buffer == NULL)
        {
            printf ("Error: not enough memory to allocate the extraction buffer\n");
            fclose (RffFile);
            return EXIT_FAILURE;
        }

        // If we want to extract all files
        if (Opt_ExtractAllFiles)
            for (Ind = 0; (uint32)Ind < NbFiles; Ind++)
                ExtractFile (FileInfos[Ind].Name);

        // Else, we just extract the requested files
        else for (Ind++; Ind < ArgC; Ind++)
            ExtractFile (ArgV[Ind]);

        free (Buffer);
    }

    printf ("\n");
    free (FileInfos);
    fclose (RffFile);
    return EXIT_SUCCESS;
}


/*
====================
ParseArg

Parse the program arguments
====================
*/
static int ParseArg (int ArgC, const char* ArgV [])
{
    // Variables
    int32 Ind;

    // Trivial checks
    if (ArgC < 3 || ArgV[1][1] != '\0' || (ArgV[1][0] != 'l' && ArgV[1][0] != 'x'))
        return -1;

    // Command checks
    switch (ArgV[1][0])
    {
        case 'l':
            Command = CMD_LIST;
            break;
        case 'x':
            Command = CMD_EXTRACT;
            break;
        default:
            return -1;
    }

    // Options checks
    for (Ind = 2; Ind < ArgC; Ind++)
    {
        // If it's not an option, return
        if (ArgV[Ind][0] != '-')
            return Ind;

        switch (ArgV[Ind][1])
        {
            // Extract ALL files
            case 'a':
                // Check if there is nothing behind the "-a"
                if (ArgV[Ind][2] == '\0')
                    Opt_ExtractAllFiles = true;

                break;

            // Buffer size
            case 'b':
                BufferSize = atoi (&ArgV[Ind][2]) * 1024;

                // Check if the buffer size is valid
                if (BufferSize == 0)
                {
                    printf ("Warning: invalid buffer size. Defaulting to %u Kb\n\n", DEFAULT_BUFFER_SIZE);
                    BufferSize = DEFAULT_BUFFER_SIZE * 1024;
                }

                break;

            // Verbose option
            case 'v':
                // Check if there is nothing behind the "-v"
                if (ArgV[Ind][2] == '\0')
                    Opt_Verbose = true;

                break;

            default:
                return -1;
        }
    }

    return -1;
}


/*
====================
VerbosePrintf

Print only if VerboseOption is true
====================
*/
static int VerbosePrintf (const char* Format, ...)
{
    // Variables
    int ReturnedValue;
    va_list Arguments;

    // Test the Verbose option
    if (! Opt_Verbose)
        return 0;

    // Print the string
    va_start (Arguments, Format);
    ReturnedValue = vprintf (Format, Arguments);
    va_end (Arguments);

    return ReturnedValue;
}
