/*
 blud2b.c

 Convert a Blood MAP file to a BUILD MAP file

 Version 0.0 beta 
*/

/* Copyright (C) 2001  Mathieu Olivier <elric@planetblood.com> and
 *					    Timothy Hale <timhale@planetblood.com>
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
    Do the loops based on the Matt S. decryption code
*/

#include <assert.h>   // assert
#include <stdio.h>    // FILE, printf, fopen, fclose, fseek, SEEK_SET, fwrite
#include <stdlib.h>   // EXIT_FAILURE, EXIT_SUCCESS
#include <string.h>   // strcmp

/* ----------------- */
/* --- Constants --- */
/* ----------------- */

// Current version of this software
#define VERSION "0.01 beta"


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
} header_t; // 16 + 6(header)

// The hard core numbers
typedef struct
{
	int MapRevisions;
	short NumSectors;
	short NumWalls;
	short NumSprites;
} mapnumbers_t;

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
} sector_t;  // 40

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
} sprite_t;  // 44

// Informations about a wall
typedef struct
{
   int x, y;
   short point2, nextwall, nextsector, cstat;
   short picnum, overpicnum;
   signed char  shade;
   unsigned char pal, xrepeat, yrepeat, xpanning, ypanning;
   short lotag, hitag, extra;
} wall_t;  // 32


/* ------------- */
/* --- Types --- */
/* ------------- */

// BUILD map file
static FILE* NewFile = NULL;

// Header infos
int PosX = 0, PosY = 0, PosZ = 0, Revisions;
short Angle = 0;
unsigned short SectorNum = 0, Sectors, Walls, Sprites;

/* ----------------- */
/* --- Functions --- */
/* ----------------- */

/* ------ Prototypes ------ */

// Check if the contents of a buffer have been correctly decrypted
static bool CheckBufferValidity (const unsigned short Size, const unsigned char* Buffer);

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

// Try to guess the decryption key for a buffer
static unsigned char GuessDecryptKey (const unsigned short Size, const unsigned char* Buffer);

// Extract infos from the header
static bool ParseHeader (FILE* SourceFile);

// Write the header of the BUILD MAP
// WARNING: change the current position in the file
static void WriteMapHeader (void);


/* ------ Implementations ------ */

/*
====================
CheckBufferValidity

Check if the contents of a buffer have been correctly decrypted
====================
*/
static bool CheckBufferValidity (const unsigned short size, const unsigned char* Buffer)
{
    // Local variables
    unsigned int i, NullCount = 0;

    assert (Buffer != NULL);

    // Count the number of 0
    for (i = 0; i < size; i++)
        if (Buffer[i] == 0)
            NullCount++;

    // If the test has failed
    if (NullCount < i / 3)
    {
        printf ("Validity test FAILED (%u / %u)\n", NullCount, i);
        return false;
    }

    return true;
}

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
    long CrtOffset = ftell (SourceFile);
    unsigned short Ind = 0;

    // Write the number of sectors
    fwrite (&Sectors, 2, 1, NewFile);

    // First sector
    if (fread (Buffer, 1, sizeof (sector_t), SourceFile) != sizeof (sector_t))
        return false;
    DecryptKey = GuessDecryptKey (sizeof (sector_t), Buffer);
     printf("Matt S. style key: 0X%02X\n\n", (Revisions * sizeof (sector_t)) & 0xFF );

    DecryptBuffer (Buffer, sizeof (sector_t), DecryptKey);

    for (Ind=0; Ind < Sectors; Ind++)
    {
        CrtOffset += sizeof (sector_t);
     
        // Save the sector to the new file
        fwrite (SectorPtr, 1, sizeof (*SectorPtr), NewFile);

        // If extra data follow
        if (SectorPtr->extra > 0) // offset to extra array
        {
            // skip the next 60 bytes
            if (fread (Buffer, 1, 60, SourceFile) != 60)
                return false;

            CrtOffset += 60;
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

        if (fread (Buffer, 1, sizeof (sector_t), SourceFile) != sizeof (sector_t))
		{
			printf("Unable to read in a sector fully\n");
			return false;
		}
        DecryptBuffer (Buffer, sizeof (sector_t), DecryptKey);
        if (! CheckBufferValidity (sizeof (sector_t), Buffer))
        break;
    }
    
    fseek (NewFile, 0, SEEK_END);

    // Go back to the beginning of the current chunk
    fseek (SourceFile, CrtOffset, SEEK_SET);
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
    long SpritesOffset = ftell (NewFile);
    unsigned short Ind = 0;

    // Write the number of sprites
    fwrite (&Ind, 2, 1, NewFile);
    Ind = 1;

    // First sprite
    if (fread (Buffer, 1, sizeof (sprite_t), SourceFile) != sizeof (sprite_t))
        return true;  // no sprite in the map ?
    DecryptKey = GuessDecryptKey (sizeof (sprite_t), Buffer);
    printf("Matt S. style key: 0X%02X\n\n", (Revisions * sizeof (sprite_t)| 0x4d) & 0xFF );
    DecryptBuffer (Buffer, sizeof (sprite_t), DecryptKey);

    // Save the sprite to the new file
    fwrite (SpritePtr, 1, sizeof (*SpritePtr), NewFile);

    // If extra data follow
    if (SpritePtr->extra > 0)
    {
        // skip the next 56 bytes
            if (fread (Buffer, 1, 56, SourceFile) != 56)
                return false;        
    }

    // Other sprites
    while (fread (Buffer, 1, sizeof (sprite_t), SourceFile) == sizeof (sprite_t))
    {
        DecryptBuffer (Buffer, sizeof (sprite_t), DecryptKey);
        
        // Save the sprite to the new file
        fwrite (SpritePtr, 1, sizeof (*SpritePtr), NewFile);

        // If extra data follow
        if (SpritePtr->extra > 0) //<= 2047 && SpritePtr->extra >= 1024)
        {
            // skip the next 56 bytes
            if (fread (Buffer, 1, 56, SourceFile) != 56)
                return false;
		}
        else switch (SpritePtr->extra)
        {
            case -1: // The end ?
                break;
            default:
                printf ("ERROR: unknown extra data value  (%hd)\n", SpritePtr->extra);
                return false;
        }

        Ind++;
    }

    // Write the real number of sectors
    fseek (NewFile, SpritesOffset, SEEK_SET);
    fwrite (&Ind, 2, 1, NewFile);
    fseek (NewFile, 0, SEEK_END);

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

    printf ("\n-> Number of walls to extract: %u\n", Walls);

    // First sector
    if (fread (Buffer, 1, sizeof (wall_t), SourceFile) != sizeof (wall_t))
        return false;
    DecryptKey = GuessDecryptKey (sizeof (wall_t), Buffer);
    printf("Matt S. style key: 0X%02X\n\n", (Revisions * sizeof (sector_t)| 0x4d) & 0xFF );
    DecryptBuffer (Buffer, sizeof (wall_t), DecryptKey);

    // Save the wall to the new file
    fwrite (WallPtr, 1, sizeof (*WallPtr), NewFile);

    // If extra data follow
    if (WallPtr->extra > 0)
    {
       // skip the next 24 bytes
            if (fread (Buffer, 1, 24, SourceFile) != 24)
                return false;
    }

    for (Ind = 1; Ind < Walls; Ind++)
    {
        if (fread (Buffer, 1, sizeof (wall_t), SourceFile) != sizeof (wall_t))
            return false;
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
GuessDecryptKey

Try to guess the decryption key for a buffer
====================
*/
static unsigned char GuessDecryptKey (const unsigned short Size, const unsigned char* Buffer)
{
    // Variables
    size_t Ind;
    unsigned int BestScore = 0;
    unsigned int CrtScore;
    unsigned char BestKey = 0;
    unsigned char CrtKey;

    // The key is probably the value of one of the bytes
    for (Ind = 0; Ind < Size; Ind++)
    {
        // Local variables
        size_t Ind2;

        // Set key to the current byte value minus its index
        CrtKey = (unsigned char)(Buffer[Ind] - Ind);
        CrtScore = 0;

        // Try this key on the buffer
        for (Ind2 = 0; Ind2 < Size; Ind2++)
            if (((unsigned char)(CrtKey + Ind2) ^ Buffer[Ind2]) == 0)
                CrtScore++;

        // If this key has the best score, record it
        if (CrtScore >= BestScore)
        {
            BestScore = CrtScore;
            BestKey   = CrtKey;
        }
    }

    printf ("Best decryption key is 0X%02X with a score of %u / %d\n", BestKey, BestScore, Size);

    return BestKey;
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
            "Blud2b version " VERSION " by Mathieu Olivier <elric@planetblood.com>\n"
			
			__DATE__"	           and Timothy Hale <timhale@planetblood.com>\n"
            "=====================================================================\n"
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
    printf ("     First sector found at offset %ld\n", StartOffset);

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

    printf ("\nExtracting...\n");

    // Extract the sectors
    if (! ExtractSectors (SourceFile))
        printf ("Error: can't extract sectors\n");
    else
    {
        printf ("Sectors successfully extracted\n");

        // Extract the walls
        if (! ExtractWalls (SourceFile))
            printf ("Error: can't extract walls\n");
        else
        {
            printf ("Walls successfully extracted\n");

            // Extract the sprites
            if (! ExtractSprites (SourceFile))
                printf ("Error: can't extract sprites\n");
            else
                printf ("Sprites successfully extracted\n");
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
    header_t Header;
	mapnumbers_t Numbers;

	char MapSignature[4];
	char MapVersion[2];

	fread(MapSignature,4,1,SourceFile);
	fread(&MapVersion,2,1,SourceFile);
		
	if (MapVersion[0] == 0x03 && MapVersion[1] == 0x06)
	{
		printf("\nblud2b can't handle 6.03 blood maps yet\n"
			   "Try bringing the map up in the latest version of mapedit, then save it.\n"
			   "This should produce a 7.0 version map, which blud2b CAN convert to build.\n");
		return false;
	} 
	else if (MapSignature[0] != 'B'  ||
			 MapSignature[1] != 'L'  ||
			 MapSignature[2] != 'M'  ||
			 MapSignature[3] != 0x1A ||
			 MapVersion[0]   != 0x00 ||
			 MapVersion[1]   != 0x07)
	
	{
		printf("\nThis files signature is not consistant with the blood map signature.\n");
		return false;
	} 

    if (fread (&Header, 1, sizeof (Header), SourceFile) != sizeof (Header))
        return false;
	
	fseek(SourceFile, 33, SEEK_SET); // The magic!
	if (fread (&Numbers, 1, sizeof (Numbers), SourceFile) != sizeof (Numbers))
        return false;

    DecryptBuffer ((unsigned char*)&Header, sizeof (Header), 0x4D);
	DecryptBuffer ((unsigned char*)&Numbers, sizeof (Numbers), 0x68);

    // Store the infos
    PosX = Header.StartX;
    PosY = Header.StartY;
    PosZ = Header.StartZ;
    Angle = Header.StartAngle;
    SectorNum = Header.SectorNum;
	Revisions = Numbers.MapRevisions;
	Sectors = Numbers.NumSectors;
	Walls = Numbers.NumWalls;
	Sprites = Numbers.NumSprites;

	printf ("      PosX = %d\n", PosX);
    printf ("      PosY = %d\n", PosY);
    printf ("      PosZ = %d\n", PosZ);
    printf ("      Angle = %hd\n", Angle);
    printf ("      SectorNum = %hd\n", SectorNum);
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
