//
// sfx2wav.c
//
// Merge a SFX file and a RAW file to create a WAV file
//
// Version 0.0
//

/* Copyright (C) 2001  Mathieu Olivier  <elric@planetblood.com>
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


#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* ----------------- */
/* --- Constants --- */
/* ----------------- */

// Current version of this software
#define VERSION "0.0"

// Contants used by the WAV header
// FIXME: use an endian-independent system instead of little endian integers
#define RIFF_MAGIC_NUMBER 0x46464952  // "RIFF"
#define WAVE_FORMAT_ID    0x45564157  // "WAVE"
#define FMT_CHUNK_ID      0x20746D66  // "fmt "
#define DATA_CHUNK_ID     0x61746164  // "data"

// Default size of Buffer in Kb
#define DEFAULT_BUFFER_SIZE 32


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


// Sound formats (thanks to Matt Saettler <matts@saettler.com>, "http://www.saettler.com/")
typedef enum
{
    SND_FMT_DEFAULT,  // 0
    SND_FMT_1M08,     // 1
    SND_FMT_1S08,     // 2
    SND_FMT_1M16,     // 3
    SND_FMT_1S16,     // 4
    SND_FMT_2M08,     // 5
    SND_FMT_2S08,     // 6
    SND_FMT_2M16,     // 7
    SND_FMT_2S16,     // 8
    SND_FMT_4M08,     // 9
    SND_FMT_4S08,     // 10
    SND_FMT_4M16,     // 11
    SND_FMT_4S16      // 12
} SoundFormat_t;

// Contents of a SFX file (thanks to "BARF.EXE")
typedef struct
{
    int32 Volume;       // Volume, 0-255
    int32 Pitch;        // Pitch change (fixed point)
    int32 PitchRange;   // Range of random pitch (fixed point)
    int32 Format;       // Format of audio (1 = 11025, 5 = 22050)
    int32 LoopStart;    // Loop position (-1 means no looping)
    char  RawName [9];  // Name of RAW resource
} SfxContents_t;

// Header of a WAV file (PCM type)
typedef struct
{
    uint32 RiffMagicNumber;    // "RIFF"
    uint32 ContentsLength;     // Total file length (without this first 2 fields)
    uint32 RiffType;           // "WAVE"
    uint32 FormatChunkId;      // "fmt "
    uint32 FormatChunkLength;  // Total chunk length (starting after this field) => 16 here
    uint16 FormatTag;          // 1 -> "Microsoft Pulse Code Modulation (PCM)"
    uint16 Channels;           // 1 -> mono, 2 -> stereo
    uint32 SamplesPerSec;      // Frequency (in Hz)
    uint32 AvgBytesPerSec;     // = Channels * SamplesPerSec * BitsPerSample / 8
    uint16 BlockAlign;         // Data block size (in bits) = Channels * BitsPerSample / 8
    uint16 BitsPerSample;      // Sample size
    uint32 DataChunkId;        // "data"
    uint32 DataChunkLength;    // Total chunk length (starting after this field) => 16 here
} WavHeader_t;


/* ------------------------ */
/* --- Global variables --- */
/* ------------------------ */

// WAV header
WavHeader_t WavHeader =
{
    RIFF_MAGIC_NUMBER,
    0,                  // TO BE FILLED: ContentsLength
    WAVE_FORMAT_ID,
    FMT_CHUNK_ID,
    16,
    1,
    0,                  // TO BE FILLED: Channels
    0,                  // TO BE FILLED: SamplesPerSec
    0,                  // TO BE FILLED: AvgBytesPerSec
    0,                  // TO BE FILLED: BlockAlign
    0,                  // TO BE FILLED: BitsPerSample
    DATA_CHUNK_ID,
    0                   // TO BE FILLED: DataChunkLength
};

// All purpose buffer (so we don't have to "malloc" one each time we need some storage)
static uint8* Buffer;
static uint32 BufferSize = DEFAULT_BUFFER_SIZE * 1024;

// Options
static bool Opt_Verbose = false;
static bool Opt_Test    = false;


/* ----------------- */
/* --- Functions --- */
/* ----------------- */

/* ------ Prototypes ------ */

// Build a WAV file based on a SFX file
static bool BuildWavFromSfx (const char* SfxFileName, SfxContents_t* SfxContents);

// Parse the program arguments
//     Returns the index of first file name in ArgV, or -1 if error
static int ParseArg (int ArgC, const char* ArgV []);

// Print only if Opt_Verbose is true
//     Returns the number of written characters, or -1 if error
static int VerbosePrintf (const char* Format, ...);


/* ------ Implementations ------ */

/*
====================
BuildWavFromSfx

Build a WAV file based on a SFX file
====================
*/
static bool BuildWavFromSfx (const char* SfxFileName, SfxContents_t* SfxContents)
{
    // Variables
    char FileName [16];
    FILE *RawFile, *WavFile;
    uint32 FileSize;
    uint32 BufferCount;
    uint32 Ind;

    // Print the SFX infos
    printf ("\n* \"%s\"\n", SfxFileName);
    VerbosePrintf ("   Properties\n"
                   "      Volume     = %d\n"
                   "      Pitch      = %d\n"
                   "      PitchRange = %d\n"
                   "      Format     = %d\n"
                   "      LoopStart  = %d\n"
                   "      RawName    = \"%s\"\n"
                   , SfxContents->Volume
                   , SfxContents->Pitch
                   , SfxContents->PitchRange
                   , SfxContents->Format
                   , SfxContents->LoopStart
                   , SfxContents->RawName
                  );

    // Do some checks
    if (SfxContents->Pitch != 65536)
        printf ("   Warning: Pitch is not 65536 (%d)\n",  SfxContents->Pitch);
    if (SfxContents->LoopStart != -1 && SfxContents->LoopStart != 0)
        printf ("   Warning: Loopstart is neither -1 nor 0 (%d)\n", SfxContents->LoopStart);

    // Fill the WAV header
    switch (SfxContents->Format)
    {
        // 11 Kz, mono, 8 bits
        case SND_FMT_1M08:
            WavHeader.Channels = 1;
            WavHeader.SamplesPerSec = 11025;
            WavHeader.AvgBytesPerSec = 11025;
            WavHeader.BlockAlign = 1;
            WavHeader.BitsPerSample = 8;
            break;

        // 22 Kz, mono, 8 bits
        case SND_FMT_2M08:
            WavHeader.Channels = 1;
            WavHeader.SamplesPerSec = 22050;
            WavHeader.AvgBytesPerSec = 22050;
            WavHeader.BlockAlign = 1;
            WavHeader.BitsPerSample = 8;
            break;
        
        // TODO: do we need to support the other format ? Blood doesn't use them anyway...

        // else, it's an unknown or unsupported format
        default:
            printf ("Error: unknown or unsupported SFX format (%d)\n", SfxContents->Format);
            return false;
    }

    // Open the corresponding RAW file
    strcpy (FileName, SfxContents->RawName);
    strcat (FileName, ".raw");
    RawFile = fopen (FileName, "rb");
    if (RawFile == NULL)
    {
        printf ("Error: can't open the RAW file \"%s\"\n", FileName);
        return false;
    }

    // If it's just a test, stop here
    if (Opt_Test)
    {
        printf ("   Test successfully passed\n");
        fclose (RawFile);
        return true;
    }

    // Build the WAV file name
    for (Ind = 0; Ind < sizeof (FileName) - 5; Ind++)
    {
        if (SfxFileName[Ind] == '.' || SfxFileName[Ind] == '\0')
            break;
        FileName[Ind] = SfxFileName[Ind];
    }
    strcpy (&FileName[Ind], ".wav");
    VerbosePrintf ("   Creating \"%s\"... ", FileName);
    fflush (stdout);

    // Create the WAV file
    WavFile = fopen (FileName, "wb");
    if (WavFile == NULL)
    {
        printf ("Error: can't create the WAV file \"%s\"\n", FileName);
        fclose (RawFile);
        return false;
    }

    // Dump the WAV header and its contents (the RAW file)
    fwrite (&WavHeader, 1, sizeof (WavHeader), WavFile);
    FileSize = sizeof (WavHeader);
    BufferCount = 0;
    do
    {
        BufferCount = fread (Buffer, 1, BufferSize, RawFile);
        if (BufferCount != 0)
            fwrite (Buffer, 1, BufferCount, WavFile);
        FileSize += BufferCount;
    } while (BufferCount == BufferSize);
    fclose (RawFile);

    // Fill the blanks (ContentsLength and  DataChunkLength)
    WavHeader.ContentsLength = FileSize - 8;
    fseek (WavFile, 4, SEEK_SET);
    fwrite (&WavHeader.ContentsLength, 1, 4, WavFile);
    WavHeader.DataChunkLength = FileSize - 44;
    fseek (WavFile, 40, SEEK_SET);
    fwrite (&WavHeader.DataChunkLength, 1, 4, WavFile);

    fclose (WavFile);
    VerbosePrintf ("done\n");
    return false;
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
    FILE* SfxFile;
    SfxContents_t SfxContents;
    int32 NbReadBytes;

    // Header
    printf ("\n"
            "Sfx2Wav version " VERSION " by Mathieu Olivier  <elric@planetblood.com>\n"
            "===============================================================\n"
            "\n"
           );

    // Check arguments
    Ind = ParseArg (ArgC, (const char**)ArgV);
    if (Ind == -1 || Ind == ArgC)
    {
        printf ("Syntax: sfx2wav [options] <sfx files ...>\n"
                "   Options:\n"
                "      '-b<buffer size>': set the extraction buffer size in Kb (default: %u Kb)\n"
                "      '-t': Test. Do NOT write WAV files to disk\n"
                "      '-v': Give the maximum amount of information during the process\n"
                "\n",
                DEFAULT_BUFFER_SIZE
               );
        return EXIT_FAILURE;
    }

    // Allocate Buffer
    VerbosePrintf ("Allocating the extraction buffer (%u Kb)\n\n", BufferSize);
    Buffer = malloc (BufferSize);
    if (Buffer == NULL)
    {
        printf ("Error: not enough memory to allocate the extraction buffer\n");
        return EXIT_FAILURE;
    }

    // Treat the current SFX file
    for (; Ind < ArgC; Ind++)
    {
        // Open the file
        SfxFile = fopen (ArgV[Ind], "rb");
        if (SfxFile == NULL)
        {
            printf ("\nError: can't open \"%s\"\n", ArgV[Ind]);
            continue;
        }

        // Read the contents (need 22 bytes at least so that the RAW file name won't be "")
        NbReadBytes = fread (&SfxContents, 1, sizeof (SfxContents), SfxFile);
        if (NbReadBytes < 22)
        {
            printf ("\nError: \"%s\" is too small to be a valid (%d bytes read, 22 needed)\n", ArgV[Ind], NbReadBytes);
            fclose (SfxFile);
            continue;
        }
        fclose (SfxFile);

        // Build the WAV file
        BuildWavFromSfx (ArgV[Ind], &SfxContents);
    }

    printf ("\n");
    free (Buffer);
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

    // Options checks
    for (Ind = 1; Ind < ArgC; Ind++)
    {
        // If it's not an option, return
        if (ArgV[Ind][0] != '-')
            return Ind;

        switch (ArgV[Ind][1])
        {
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

            // Test option
            case 't':
                // Check if there is nothing behind the "-t"
                if (ArgV[Ind][2] == '\0')
                    Opt_Test = true;

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

    return Ind;
}


/*
====================
VerbosePrintf

Print only if Opt_Verbose is true
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
