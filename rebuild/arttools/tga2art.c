//
// tga2art.c
//
// Create an ART file from TGA files
//
// Version 0.0
//

/* Copyright (C) 2000  Mathieu Olivier
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

// This work is based on the source code of Kenneth Silverman's BUILD 3D
// engine and utilities. You can find Ken Silverman's official web site
// at "http://www.advsys.net/ken".


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* ----------------- */
/* --- Constants --- */
/* ----------------- */

// Maximum number of tiles (taken from Ken's "editart.c")
#define MAX_NB_TILES 9216

// Maximum sizes for the parsing of "animdata.ini"
#define MAX_KEY_SIZE   128  // max size of a section name or a key
#define MAX_VALUE_SIZE 128  // max size of the value of a key

// Size of the color palette (256 colors, 3 components for each color)
#define PALETTE_SIZE (256 * 3)

// Current version of this software
#define VERSION "0.0"

// Animation types
static const char* AnimationTypes [4] = {"none", "oscillation", "forward", "backward"};


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

// Description of a tile
typedef struct {
   uint16 XSize;     // Tile's width
   uint16 YSize;     // Tile's height
   uint32 AnimData;  // Flags and values for animating the picture
   uint32 Offset;    // Offset in the ART file
} Tile_t;

// Type of a line in an INI file
typedef enum {
   LINE_TYPE_UNKNOWN,    // syntax error
   LINE_TYPE_SECTION,    // beginning of a section 
   LINE_TYPE_KEY_VALUE,  // key / value pair
   LINE_TYPE_EOF         // end of file
} LineType_e;


/* ------------------------ */
/* --- Global variables --- */
/* ------------------------ */

// List of tiles in the ART file
static uint32 NbTiles = 0;
static uint32 TilesStartNum = 0;         // Number of the first tile
static Tile_t TilesList [MAX_NB_TILES];

// Color palette (in TGA format: set of {Blue, Green, Red})
static bool PaletteCreated = false;  // we can't just verify this by checking the tile index
static uint8 Palette [PALETTE_SIZE];


/* ----------------- */
/* --- Functions --- */
/* ----------------- */

/* ------ Prototypes ------ */

// Create the ART file
static bool CreateArtFile (const char* ArtFileName);

// Extract key and value from the next line of an INI file
static LineType_e ExtractAnimDataLine (FILE* AnimDataFile, char* Key, char* Value);

// Extract animation data from "animdata.ini"
static void GetAnimData (void);

// Get a uint16 from a little-endian ordered buffer
static uint16 GetLittleEndianUInt16 (const uint8* Buffer);

// Read / check the color palette
static bool HandlePalette (FILE* TgaFile, const char* TgaFileName);

// Set a uint16 into a little-endian ordered buffer
static void SetLittleEndianUInt16 (uint16 Integer, uint8* Buffer);

// Set a uint32 into a little-endian ordered buffer
static void SetLittleEndianUInt32 (uint32 Integer, uint8* Buffer);

// Dump the content of a TGA file into the ART file
// and save its properties into TilesList
static bool TreatTgaFile (uint32 TgaInd, FILE* ArtFile);


/* ------ Implementations ------ */

/*
====================
CreateArtFile

Create the ART file
====================
*/
static bool CreateArtFile (const char* ArtFileName)
{
   // Variables
   FILE* ArtFile;
   uint8 Buffer [16 + MAX_NB_TILES * (2 + 2 + 4)];
   uint32 Ind;

   // Create the file
   ArtFile = fopen (ArtFileName, "wb");
   if (ArtFile == NULL)
   {
      printf ("Error: can't create \"%s\"\n", ArtFileName);
      return false;
   }

   // Write the ART header (first pass)
   SetLittleEndianUInt32 (1,                           &Buffer[ 0]);  // ART version number
   SetLittleEndianUInt32 (TilesStartNum + NbTiles,     &Buffer[ 4]);  // total number of tiles
   SetLittleEndianUInt32 (TilesStartNum,               &Buffer[ 8]);  // number of the first tile
   SetLittleEndianUInt32 (TilesStartNum + NbTiles - 1, &Buffer[12]);  // number of the last tile
   // We can't fill the tiles properties now. It will be done later
   fwrite (Buffer, 1, 16 + NbTiles * (2 + 2 + 4), ArtFile);

   // For each tile, dump its content into ART file and save its properties
   for (Ind = 0; Ind < NbTiles; Ind++)
      if (! TreatTgaFile (Ind, ArtFile))
         printf ("       TGA file skipped\n");

   // Extract animation data from "animdata.ini"
   GetAnimData ();
      
   // --- Write the ART header (second pass) --- //
   if (fseek (ArtFile, 16, SEEK_SET) != 0)
   {
      printf ("Error: can't go to the beginning of the ART file to write its header\n");
      fclose (ArtFile);
      return false;
   }
   // Write sizes
   for (Ind = 0; Ind < NbTiles; Ind++)
      SetLittleEndianUInt16 (TilesList[Ind].XSize, &Buffer[Ind * 2]);
   fwrite (Buffer, 1, NbTiles * 2, ArtFile);
   for (Ind = 0; Ind < NbTiles; Ind++)
      SetLittleEndianUInt16 (TilesList[Ind].YSize, &Buffer[Ind * 2]);
   fwrite (Buffer, 1, NbTiles * 2, ArtFile);

   // Write animation data
   for (Ind = 0; Ind < NbTiles; Ind++)
      SetLittleEndianUInt32 (TilesList[Ind].AnimData, &Buffer[Ind * 4]);
   fwrite (Buffer, 1, NbTiles * 4, ArtFile);

   fclose (ArtFile);
   return true;
}


/*
====================
ExtractAnimDataLine

Extract key and value from the next line of an INI file
====================
*/
static LineType_e ExtractAnimDataLine (FILE* AnimDataFile, char* Key, char* Value)
{
   // Variables
   char Line [128];
   char* CharPtr;
   uint32 KeyInd, ValueInd;

   // Extract the next line
   while (fgets (Line, sizeof (Line), AnimDataFile) != NULL)
   {
      // Skip whitespaces
      CharPtr = Line;
      while (*CharPtr == ' ')
         CharPtr++;

      // So, what is this line ?
      switch (*CharPtr)
      {
         // Beginning of a new section
         case '[':
            // Skip whitespaces
            CharPtr++;
            while (*CharPtr == ' ')
               CharPtr++;

            // Extract the name of the section
            KeyInd = 0;
            while (*CharPtr != ']' && *CharPtr != '\0')
               Key[KeyInd++] = *CharPtr++;
            Key[KeyInd] = '\0';
            Value[0] = '\0';

            // If the line is invalid
            if (*CharPtr == '\0')
               return LINE_TYPE_UNKNOWN;

            // Remove trailing spaces in Key string
            while (KeyInd > 0 && Key[KeyInd - 1] == ' ')
               Key[--KeyInd] = '\0';

            return LINE_TYPE_SECTION;

         // Empty line or comments. Just go to next line
         case '\n':
         case ';':
            break;

         // Should be a key / value pair
         default:
            // Extract the key
            KeyInd = 0;
            while (*CharPtr != '=' && *CharPtr != '\0')
               Key[KeyInd++] = *CharPtr++;
            Key[KeyInd] = '\0';
            Value[0] = '\0';

            // If the line is invalid
            if (*CharPtr == '\0')
               return LINE_TYPE_UNKNOWN;

            // Remove trailing spaces in Key string
            while (KeyInd > 0 && Key[KeyInd - 1] == ' ')
               Key[--KeyInd] = '\0';

            // Skip whitespaces
            CharPtr++;
            while (*CharPtr == ' ')
               CharPtr++;

            // Extract the value
            ValueInd = 0;
            while (*CharPtr != '\n' && *CharPtr != '\0')
               Value[ValueInd++] = *CharPtr++;
            Value[ValueInd] = '\0';

            // Remove trailing spaces in Value string
            while (ValueInd > 0 && Value[ValueInd - 1] == ' ')
               Value[--ValueInd] = '\0';

            return LINE_TYPE_KEY_VALUE;
      }
   }

   return LINE_TYPE_EOF;
}


/*
====================
GetAnimData

Extract animation data from "animdata.ini"
====================
*/
static void GetAnimData (void)
{
   // Variables
   FILE* AnimDataFile;
   LineType_e LineType;
   uint32 CrtTileInd, TileInd1, TileInd2;
   int32 Integer;
   char Key [MAX_KEY_SIZE], Value [MAX_VALUE_SIZE];
   char* CharPtr;
   bool ValidSection;

   // Open "animdata.ini"
   AnimDataFile = fopen ("animdata.ini", "rt");
   if (AnimDataFile == NULL)
   {
      printf ("Warning: \"animdata.ini\" not found. No animation data added\n");
      return;
   }
   printf ("Parsing \"animdata.ini\"\n");

   // Treat each line...
   CrtTileInd = 0;
   LineType = ExtractAnimDataLine (AnimDataFile, Key, Value);
   while (LineType != LINE_TYPE_EOF)
   {
      switch (LineType)
      {
         // Key / value pair
         case LINE_TYPE_KEY_VALUE:
            // Animation keys
            if (strcmp (Key, "AnimationType") == 0)
            {
               // Seek the animation type in our list
               for (Integer = 0; Integer < 4; Integer++)
                  if (strcmp (AnimationTypes[Integer], Value) == 0)
                     break;

               // If the animation type is invalid
               if (Integer == 4)
               {
                  printf ("Error: invalid animation type (%s)\n", Value);
                  break;
               }
               TilesList[CrtTileInd].AnimData &= 0xFFFFFF3F;
               TilesList[CrtTileInd].AnimData |= (Integer & 0x03) << 6;
            }
            else if (strcmp (Key, "AnimationSpeed") == 0)
            {
               Integer = atoi (Value);
               TilesList[CrtTileInd].AnimData &= 0xF0FFFFFF;
               TilesList[CrtTileInd].AnimData |= (Integer & 0x0F) << 24;
            }
            // Tile keys
            else if (strcmp (Key, "XCenterOffset") == 0)
            {
               Integer = atoi (Value);
               TilesList[CrtTileInd].AnimData &= 0xFFFF00FF;
               TilesList[CrtTileInd].AnimData |= (uint8)((int8)Integer) << 8;
            }
            else if (strcmp (Key, "YCenterOffset") == 0)
            {
               Integer = atoi (Value);
               TilesList[CrtTileInd].AnimData &= 0xFF00FFFF;
               TilesList[CrtTileInd].AnimData |= (uint8)((int8)Integer) << 16;
            }
            else if (strcmp (Key, "OtherFlags") == 0)
            {
               Integer = atoi (Value);
               TilesList[CrtTileInd].AnimData &= 0x0FFFFFFF;
               TilesList[CrtTileInd].AnimData |= (uint8)Integer << 28;
            }
            // Unknown key
            else
               printf ("Error: unknown key (%s)\n", Key);

            break;

         // Beginning of a new section (AND end of the current one)
         // FIXME: Clean this dirty section !!!!
         case LINE_TYPE_SECTION:
            do
            {
               ValidSection = false;

               // If it's an animation section
               CharPtr = strstr (Key, "->");
               if (CharPtr != NULL)
              {
                  // Extract the tile numbers
                  if (sscanf (Key, "tile%u.tga -> tile%u.tga", &TileInd1, &TileInd2) != 2)
                     printf ("Error: invalid section name (%s)\n", Key);
                  // If the first tile number is invalid
                  else if (TileInd1 < TilesStartNum || TileInd1 >= TilesStartNum + NbTiles)
                     printf ("Error: invalid tile number (%u)\n", TileInd1);
                  // If the second tile number is invalid
                  else if (TileInd2 < TilesStartNum || TileInd2 >= TilesStartNum + NbTiles)
                     printf ("Error: invalid tile number (%u)\n", TileInd2);
                  // If the first tile number is greater than the second one
                  else if (TileInd1 > TileInd2)
                     printf ("Error: first tile number greater than second one (%u > %u)\n", TileInd1, TileInd2);
                  // All is good
                  else
                  {
                     CrtTileInd = TileInd1 - TilesStartNum;
                     TilesList[CrtTileInd].AnimData &= 0xFFFFFFC0;
                     TilesList[CrtTileInd].AnimData |= (TileInd2 - TileInd1) & 0x3F;
                     ValidSection = true;
                  }
               }

               // Else (it's a tile properties section)
               else
               {
                  // If we can't extract the tile number
                  if (sscanf (Key, "tile%u.tga", &TileInd1) != 1)
                     printf ("Error: invalid section name (%s)\n", Key);
                  // Else, if the tile number is invalid
                  else if (TileInd1 < TilesStartNum || TileInd1 >= TilesStartNum + NbTiles)
                     printf ("Error: invalid tile number (%u)\n", TileInd1);
                  else
                  {
                     CrtTileInd = TileInd1 - TilesStartNum;
                     ValidSection = true;
                  }
               }

               // Go to the next section if we've found an invalid one
               if (! ValidSection)
               {
                  LineType = ExtractAnimDataLine (AnimDataFile, Key, Value);
                  while (LineType != LINE_TYPE_SECTION)
                  {
                     // If it's the end of the file, we quit
                     if (LineType == LINE_TYPE_EOF)
                     {
                        fclose (AnimDataFile);
                        return;
                     }
                     LineType = ExtractAnimDataLine (AnimDataFile, Key, Value);
                  }
               }
            } while (! ValidSection);
            break;

         // Syntax error
         default:
            assert (LineType == LINE_TYPE_UNKNOWN);  // paranoid verification...
            printf ("   Warning: syntax error while parsing line \"%s\"\n", Key);
            break;
      }

      // Parse next line
      LineType = ExtractAnimDataLine (AnimDataFile, Key, Value);
   }

   fclose (AnimDataFile);
}


/*
====================
GetLittleEndianUInt16

Get a uint16 from a little-endian ordered buffer
====================
*/
static uint16 GetLittleEndianUInt16 (const uint8* Buffer)
{
   return (uint16)(Buffer[0] | (Buffer[1] << 8));
}


/*
====================
HandlePalette

Read / check the color palette
====================
*/
static bool HandlePalette (FILE* TgaFile, const char* TgaFileName)
{
   // If the palette hasn't already been created, put it into
   // memory (TODO: and create a "palette.dat" file)
   if (! PaletteCreated)
   {
      // Read the palette
      if (fread (Palette, 1, PALETTE_SIZE, TgaFile) != PALETTE_SIZE)
      {
         printf ("Error: can't read the color palette from \"%s\"\n", TgaFileName);
         return false;
      }

      PaletteCreated = true;
   }

   // If the palette has already been created, verify that the
   // palette in memory is the same as the one in the current TGA
   else
   {
      // Local variables
      uint8 CrtPalette [PALETTE_SIZE];

      // Read the palette
      if (fread (CrtPalette, 1, PALETTE_SIZE, TgaFile) != PALETTE_SIZE)
      {
         printf ("Error: can't read the color palette from \"%s\"\n", TgaFileName);
         return false;
      }

      // Compare it with the reference one
      if (memcmp (CrtPalette, Palette, PALETTE_SIZE) != 0)
      {
         printf ("Error: \"%s\" palette is not the same as the reference palette\n", TgaFileName);
         return false;
      }
   }

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
   uint32 TilesEndNum;

   // Header
   printf ("\n"
           "Tga2Art version " VERSION " by Mathieu Olivier\n"
           "======================================\n\n"
          );

   // Check arguments
   if (ArgC != 4)
   {
      printf ("Syntax: Tga2Art ART_file number_of_the_first_tile number_of_the_last_tile\n"
              "   Create an ART file using TGA files tileXXXX.tga to tileYYYY.tga\n"
              "   Ex: Tga2Art tiles000.art 256 511\n"
              "\n"
             );
      return EXIT_FAILURE;
   }
   TilesStartNum = atoi (ArgV[2]);
   TilesEndNum   = atoi (ArgV[3]);
   NbTiles = TilesEndNum - TilesStartNum + 1;
   if (TilesStartNum > TilesEndNum)
   {
      printf ("Error: the number of the first tile is greater than the number of the last tile\n");
      return EXIT_FAILURE;
   }

   // Create the ART file
   if (! CreateArtFile (ArgV[1]))
      return EXIT_FAILURE;

   return EXIT_SUCCESS;
}


/*
====================
SetLittleEndianUInt16

Set a uint16 into a little-endian ordered buffer
====================
*/
static void SetLittleEndianUInt16 (uint16 Integer, uint8* Buffer)
{
   Buffer[0] = (uint8)(Integer & 255);
   Buffer[1] = (uint8)(Integer >> 8);
}


/*
====================
SetLittleEndianUInt32

Set a uint32 into a little-endian ordered buffer
====================
*/
static void SetLittleEndianUInt32 (uint32 Integer, uint8* Buffer)
{
   Buffer[0] = (uint8)( Integer        & 255);
   Buffer[1] = (uint8)((Integer >>  8) & 255);
   Buffer[2] = (uint8)((Integer >> 16) & 255);
   Buffer[3] = (uint8)( Integer >> 24       );
}


/*
====================
TreatTgaFile

Dump the content of a TGA file into the ART file
and save its properties into TilesList
====================
*/
static bool TreatTgaFile (uint32 TgaInd, FILE* ArtFile)
{
   // Variables
   char TgaFileName [] = "tile0000.tga";
   FILE* TgaFile;
   const static uint8 ReferenceTgaHeader [] = {
      0x00,                          // Number of Characters in Identification Field (0)
      0x01,                          // Color Map Type (true)
      0x01,                          // Image Type Code (1 -> uncompressed color mapped)
      0x00, 0x00, 0x00, 0x01, 0x18,  // Color Map Specification (256 colors of 24 bits, starting from 0)
      0x00, 0x00, 0x00, 0x00,        // Origin of Image (0, 0)
      0x00, 0x00, 0x00, 0x00,        // Size of Image (TO BE FILLED. Bytes 12-13 and 14-15. little-endian)
      0x08,                          // Pixel size (8 bits)
      0x00                           // Flags (image described from bottom left; no alpha)
   };
   uint8* Buffer;
   uint16 XSize, YSize;
   int32 XInd, YInd;

   // Initialize the tile properties
   TilesList[TgaInd].AnimData = 0;
   TilesList[TgaInd].Offset   = ftell (ArtFile);
   TilesList[TgaInd].XSize    = 0;
   TilesList[TgaInd].YSize    = 0;

   // Open the TGA file
   sprintf (&TgaFileName[4], "%04u.tga", TgaInd + TilesStartNum);
   TgaFile = fopen (TgaFileName, "rb");
   if (TgaFile == NULL)
   {
      printf ("Warning: can't open file \"%s\"\n", TgaFileName);
      return false;
   }

   // Parse the header
   Buffer = malloc (sizeof (ReferenceTgaHeader));
   if (Buffer == NULL)
   {
      fclose (TgaFile);
      printf ("Error: not enough memory to parse \"%s\" header\n", TgaFileName);
      return false;
   }
   if (fread (Buffer, 1, sizeof (ReferenceTgaHeader), TgaFile) != sizeof (ReferenceTgaHeader))
   {
      free (Buffer);
      fclose (TgaFile);
      printf ("Error: can't read enough data to parse \"%s\" header\n", TgaFileName);
      return false;
   }
   // FIXME: write a smarter TGA parser
   XSize = GetLittleEndianUInt16 (&Buffer[12]);
   YSize = GetLittleEndianUInt16 (&Buffer[14]);
   Buffer[12] = 0; Buffer[13] = 0;  // Reset XSize and YSize values for an
   Buffer[14] = 0; Buffer[15] = 0;  // easy comparison of other fields
   if (memcmp (ReferenceTgaHeader, Buffer, sizeof (ReferenceTgaHeader)) != 0)
   {
      free (Buffer);
      fclose (TgaFile);
      printf ("Error: invalid tga header (%s)\n", TgaFileName);
      return false;
   }
   free (Buffer);

   // Read / check the color palette
   if (! HandlePalette (TgaFile, TgaFileName))
   {
      fclose (TgaFile);
      return false;
   }

   // Read the picture
   Buffer = malloc (XSize * YSize);
   if (Buffer == NULL)
   {
      fclose (TgaFile);
      printf ("Error: not enough memory to read \"%s\" picture\n", TgaFileName);
      return false;
   }
   if (fread (Buffer, 1, XSize * YSize, TgaFile) != (uint32)(XSize * YSize))
   {
      free (Buffer);
      fclose (TgaFile);
      printf ("Error: can't read the whole picture from \"%s\"\n", TgaFileName);
      return false;
   }
   // ART file store pictures by columns, not by lines and
   // the TGA format we use saves the lines from bottom to top
   for (XInd = 0; XInd < XSize; XInd++)
      for (YInd = YSize - 1; YInd >= 0; YInd--)
         fwrite (&Buffer[YInd * XSize + XInd], 1, 1, ArtFile);
   free (Buffer);

   TilesList[TgaInd].XSize = XSize;
   TilesList[TgaInd].YSize = YSize;
   fclose (TgaFile);
   return true;
}
