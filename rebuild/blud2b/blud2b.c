/*
 blud2b.c

 Convert a Blood MAP file to a BUILD MAP file
*/

/* Copyright (C) 2001-2010  Mathieu Olivier and Timothy Hale
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

/*  TODO / WISH list
    Try to differentiate between user and official maps.
    Try to find the first sector the right way
    Try to figure out what all the other values are in the header.
    Try to figure out the skies/copyright stuff
    Make it work on big-endian machines
*/

#include <assert.h>   // assert
#include <stdio.h>    // FILE, printf, fopen, fclose, fseek, SEEK_SET, fwrite
#include <stdlib.h>   // EXIT_FAILURE, EXIT_SUCCESS
#include <string.h>   // strcmp

/* ----------------- */
/* --- Constants --- */
/* ----------------- */

// Current version of this software
#define VERSION "1.0 beta"


/* ------------- */
/* --- Types --- */
/* ------------- */

// Boolean
#ifndef __cplusplus  // Standard C++ has already this "bool"
    typedef enum { false, true } bool;
#endif

// Header structure
typedef struct
{
    int StartX;
    int StartY;
    int StartZ;
    short StartAngle;
    short SectorNum;
} header_part1_t; // size = 16, preceded by a 6-byte header (4 bytes for a magic number + 2 bytes for the version)

// The hard core numbers
typedef struct
{
    int MapRevisions;
    short NumSectors;
    short NumWalls;
    short NumSprites;
} header_part3_t; // size = 10

// Informations about a sector

typedef struct
{
    short wallptr, wallnum;
    int ceilingz, floorz;
    short ceilingstat, floorstat;
    short ceilingpicnum, ceilingheinum;
    signed char  ceilingshade;
    unsigned char ceilingpal, ceilingxpanning, ceilingypanning;
    short floorpicnum, floorheinum;
    signed char  floorshade;
    unsigned char floorpal, floorxpanning, floorypanning;
    unsigned char visibility, filler; // Filler "should" == 0
    short lotag, hitag, extra;
} sector_t;  // size = 40

// Informations about a sprite
typedef struct
{
    int x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler;
    unsigned char xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum;
    short ang, owner, xvel, yvel, zvel;
    short lotag, hitag, extra;
} sprite_t;  // size = 44

// Informations about a wall
typedef struct
{
   int x, y;
   short point2, nextwall, nextsector, cstat;
   short picnum, overpicnum;
   signed char  shade;
   unsigned char pal, xrepeat, yrepeat, xpanning, ypanning;
   short lotag, hitag, extra;
} wall_t;  // size = 32


/* ------------- */
/* --- Types --- */
/* ------------- */

// BUILD map file
static FILE* NewFile = NULL;

// Header infos
int PosX = 0, PosY = 0, PosZ = 0, Revisions;
short Angle = 0;
unsigned short SectorNum = 0, Sectors, Walls, Sprites;
bool IsEncrypted = true;

/* ----------------- */
/* --- Functions --- */
/* ----------------- */

/* ------ Prototypes ------ */

// Decrypt a buffer
static void DecryptBuffer (unsigned char* Buffer, const size_t DataSize, unsigned char DecryptKey);

// Extract all sectors from the source file
bool ExtractSectors (FILE* SourceFile);

// Extract all sprites from the source file
bool ExtractSprites (FILE* SourceFile);

// Extract all walls from the source file
bool ExtractWalls (FILE* SourceFile);

// Seek the first sector offset
static long FindFirstSector (FILE* SourceFile);

// Extract infos from the header
static bool ParseHeader (FILE* SourceFile);

// Write the header of the BUILD MAP
// WARNING: change the current position in the file
static void WriteMapHeader (void);


/* ------ Implementations ------ */

/*
====================
DecryptBuffer

Decrypt a buffer
====================
*/
static void DecryptBuffer (unsigned char* Buffer, const size_t DataSize, unsigned char DecryptKey)
{
    // Variables
    unsigned short i;

    assert (Buffer != NULL);

    // If the map isn't encrypted
    if (! IsEncrypted)
        return;

    // Decryption
    for (i = 0; i < DataSize; i++)
        Buffer[i] ^= (unsigned char)(DecryptKey + i);
}

/*
====================
ExtractSectors

Extract all sectors from the source file
====================
*/
bool ExtractSectors (FILE* SourceFile)
{
    // Variables
    unsigned char Buffer [128];
    unsigned char DecryptKey;
    const sector_t* SectorPtr = (const sector_t*)Buffer;
    unsigned short Ind = 0;

    // Write the number of sectors
    fwrite (&Sectors, 2, 1, NewFile);

    DecryptKey = ((Revisions * sizeof (sector_t)) & 0xFF);

    for (Ind = 0; Ind < Sectors; Ind++)
    {
        if (fread (Buffer, 1, sizeof (sector_t), SourceFile) != sizeof (sector_t))
        {
            printf("Unable to read sector %u fully\n", Ind);
            return false;
        }

        DecryptBuffer (Buffer, sizeof (sector_t), DecryptKey);

         // Save the sector to the new file
        fwrite (SectorPtr, 1, sizeof (*SectorPtr), NewFile);

        // If extra data follow
        if (SectorPtr->extra > 0) // offset to extra array
        {
            // skip the next 60 bytes
            if (fread (Buffer, 1, 60, SourceFile) != 60)
            {
                printf("Unable to skip extra data in sector %u\n", Ind);
                return false;
            }
        }
        else switch (SectorPtr->extra)
        {
            case 0:
            case -1:
				break;
            default:
                printf ("ERROR: unknown extra data value (%hd)\n", SectorPtr->extra);
                return false;
        }
    }

    return true;
}

/*
====================
ExtractSprites

Extract all sprites from the source file
====================
*/
bool ExtractSprites (FILE* SourceFile)
{
    // Variables
    unsigned char Buffer [128];
    unsigned char DecryptKey;
    const sprite_t* SpritePtr = (const sprite_t*)Buffer;
    unsigned short Ind;

    // Write the number of sprites
    fwrite (&Sprites, 2, 1, NewFile);

    DecryptKey = (((Revisions * sizeof (sprite_t)) | 0x4d) & 0xFF);

    for (Ind = 0; Ind < Sprites; Ind++)
    {
        if (fread (Buffer, 1, sizeof (sprite_t), SourceFile) != sizeof (sprite_t))
        {
            printf("Unable to read in a sprite %u fully\n", Ind);
            return false;
        }

        DecryptBuffer (Buffer, sizeof (sprite_t), DecryptKey);

        // Save the sprite to the new file
        fwrite (SpritePtr, 1, sizeof (*SpritePtr), NewFile);

        // If extra data follow
        if (SpritePtr->extra > 0) //<= 2047 && SpritePtr->extra >= 1024)
        {
            // skip the next 56 bytes
            if (fread (Buffer, 1, 56, SourceFile) != 56)
            {
                printf("Unable to skip extra data in sprite %u\n", Ind);
                return false;
            }
        }
        else switch (SpritePtr->extra)
        {
            case -1: // The end ?
                break;
            default:
                printf ("ERROR: unknown extra data value  (%hd)\n", SpritePtr->extra);
                return false;
        }
    }

    return true;
}

/*
====================
ExtractWalls

Extract all walls from the source file
====================
*/
bool ExtractWalls (FILE* SourceFile)
{
    // Variables
    unsigned char Buffer [128];
    unsigned char DecryptKey;
    unsigned int Ind;
    const wall_t* WallPtr = (const wall_t*)Buffer;

    assert (Walls > 0);

    // Write the number of walls
    fwrite (&Walls, 2, 1, NewFile);

    DecryptKey = (((Revisions * sizeof (sector_t)) | 0x4d) & 0xFF);

    for (Ind = 0; Ind < Walls; Ind++)
    {
        if (fread (Buffer, 1, sizeof (wall_t), SourceFile) != sizeof (wall_t))
        {
            printf("Unable to read in a wall %u fully\n", Ind);
            return false;
        }

        DecryptBuffer (Buffer, sizeof (wall_t), DecryptKey);

        // Save the wall to the new file
        fwrite (WallPtr, 1, sizeof (*WallPtr), NewFile);

        // If extra data follow
        if (WallPtr->extra > 0) // TESTME: <= 511 && WallPtr->extra >= 256
        {
            // skip the next 24 bytes
            if (fread (Buffer, 1, 24, SourceFile) != 24)
                return false;
        }
        else switch (WallPtr->extra)
        {
            case 0:
            case -1:
                break;
            default:
                printf ("ERROR: unknown extra data value (%hd)\n", WallPtr->extra);
                return false;
        }
    }

    return true;
}


/*
====================
FindFirstSector

Seek the first sector offset
====================
*/
static long FindFirstSector (FILE* SourceFile)
{
    // Variables
    unsigned short Buffer;

    assert (SourceFile != NULL);

    if (! IsEncrypted)
        return 75;

    if (fseek (SourceFile, 171, SEEK_SET) != 0)
        return -1;

    if (fread (&Buffer, 1, 2, SourceFile) != 2)
        return -2;

    switch (Buffer)
    {
        case 0x2120 :
            return 203;

        case 0x0302 :
            return 173;

        case 0x1110 : // E2M7
            return 187; // Try every 40 against Matt S. key if it doesn't work

        default :
            printf ("     -> Unknown map format\n");
            printf ("     -> %x\n", Buffer);
            return -3;
    }
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
    FILE* SourceFile;
    long StartOffset;

    // Header
    printf ("\n"
            "Blud2b, version " VERSION " - " __DATE__ "\n"
            "By Mathieu Olivier and Timothy Hale\n"
            "========================================\n"
            "\n");

    // Check parameters
    if (ArgC < 3)
    {
        printf ("Syntax: blud2b <Blood MAP file> <BUILD MAP file>\n");
        return EXIT_FAILURE;
    }

    // Open Blood MAP file
    printf ("   * Opening file \"%s\"...\n", ArgV[1]);
    SourceFile = fopen (ArgV[1], "rb");
    if (SourceFile == NULL)
    {
        printf ("ERROR\n");
        return EXIT_FAILURE;
    }

    // Creating BUILD MAP file
    printf ("   * Creating BUILD MAP file \"%s\"...\n", ArgV[2]);
    NewFile = fopen (ArgV[2], "wb");
    if (NewFile == NULL)
    {
        perror ("ERROR\n");
        fclose (SourceFile);
        return EXIT_FAILURE;
    }

    // Extract infos from the header
    printf ("   * Parsing header...\n");
    if (!ParseHeader (SourceFile))
    {
        printf ("     Error while parsing the header\n");
        fclose (NewFile);
        fclose (SourceFile);
        return EXIT_FAILURE;
    }

    // Find the first sector's offset
    printf ("   * Seeking first sector...\n");
    StartOffset = FindFirstSector (SourceFile);
    if (StartOffset < 0)
    {
        printf ("     Can't find it (error %ld) ! Exiting...\n", -StartOffset);
        fclose (NewFile);
        fclose (SourceFile);
        return EXIT_FAILURE;
    }
    printf ("      First sector found at offset %ld\n", StartOffset);

    // Positioning...
    if (fseek (SourceFile, StartOffset, SEEK_SET) != 0)
    {
        printf ("   Error: can't go to starting position\n");
        fclose (NewFile);
        fclose (SourceFile);
        return EXIT_FAILURE;
    }

    // Write temporary MAP header
    WriteMapHeader ();

    // Extract the sectors
    printf ("   * Extracting sectors...\n");
    if (! ExtractSectors (SourceFile))
        printf ("      ERROR\n");
    else
    {
        // Extract the walls
        printf ("   * Extracting walls...\n");
        if (! ExtractWalls (SourceFile))
        printf ("      ERROR\n");
        else
        {
            // Extract the sprites
            printf ("   * Extracting sprites...\n");
            if (! ExtractSprites (SourceFile))
                printf ("      ERROR\n");
            else
                printf ("\n   Done!\n");
         }
    }

    fclose (NewFile);
    fclose (SourceFile);

    return EXIT_SUCCESS;
}

/*
====================
ParseHeader

Extract infos from the header
====================
*/
static bool ParseHeader (FILE* SourceFile)
{
    // Variables
    header_part1_t Header1;
    header_part3_t Header3;

    char MapSignature[4];
    struct
    {
        unsigned char Minor, Major;
    } MapVersion;

    fread(MapSignature,4,1,SourceFile);
    fread(&MapVersion,2,1,SourceFile);

    if (MapSignature[0] != 'B'  ||
        MapSignature[1] != 'L'  ||
        MapSignature[2] != 'M'  ||
        MapSignature[3] != 0x1A )
    {
        printf("\nThe file's signature does not match the blood map signature.\n");
        return false;
    }

    printf ("      Version = %u.%u\n", MapVersion.Major, MapVersion.Minor);

    if (MapVersion.Major == 6 && MapVersion.Minor == 3)
        IsEncrypted = false;
    else if (MapVersion.Major == 7 && MapVersion.Minor == 0)
        IsEncrypted = true;
    else
    {
        printf("\nBlud2b can only handle map versions 6.3 and 7.0.\n"
               "Try bringing the map up in the latest version of mapedit, then save it.\n"
               "This should produce a 7.0 version map, which blud2b CAN convert to build.\n");
        return false;
    }

    // Load and decrypt the first part of the header
    if (fread (&Header1, 1, sizeof (Header1), SourceFile) != sizeof (Header1))
        return false;
    DecryptBuffer ((unsigned char*)&Header1, sizeof (Header1), 0x4D);

    // Store the infos
    PosX = Header1.StartX;
    PosY = Header1.StartY;
    PosZ = Header1.StartZ;
    Angle = Header1.StartAngle;
    SectorNum = Header1.SectorNum;

    printf ("      PosX = %d\n", PosX);
    printf ("      PosY = %d\n", PosY);
    printf ("      PosZ = %d\n", PosZ);
    printf ("      Angle = %hd\n", Angle);
    printf ("      SectorNum = %hd\n", SectorNum);

    // Skip the part 2 of the header, since we don't know what it is, and we don't care
    fseek(SourceFile, 11, SEEK_CUR);

    // Load and decrypt the third part of the header
    if (fread (&Header3, 1, sizeof (Header3), SourceFile) != sizeof (Header3))
        return false;
    DecryptBuffer ((unsigned char*)&Header3, sizeof (Header3), 0x68);

    // Store the infos
    Revisions = Header3.MapRevisions;
    Sectors = Header3.NumSectors;
    Walls = Header3.NumWalls;
    Sprites = Header3.NumSprites;

    printf ("      Maprevisions = %d\n", Revisions);
    printf ("      NumSectors = %d\n", Sectors);
    printf ("      NumWalls = %d\n", Walls);
    printf ("      NumSprites = %d\n", Sprites);

    return true;
}

/*
====================
WriteMapHeader

Write the header of the BUILD MAP
====================
*/
static void WriteMapHeader (void)
{
    // Variables
    const unsigned int Version = 7;

    // Be sure we're at the beginning of the file
    fseek (NewFile, 0, SEEK_SET);

    fwrite (&Version,   4, 1, NewFile);
    fwrite (&PosX,      4, 1, NewFile);
    fwrite (&PosY,      4, 1, NewFile);
    fwrite (&PosZ,      4, 1, NewFile);
    fwrite (&Angle,     2, 1, NewFile);
    fwrite (&SectorNum, 2, 1, NewFile);
}
