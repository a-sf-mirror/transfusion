//
// art2tga.c
//
// Extract pictures from an ART file under the TGA format
//
// Version 0.1
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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


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


/* ----------------- */
/* --- Constants --- */
/* ----------------- */

// Maximum number of tiles (taken from Ken's "editart.c")
#define MAX_NB_TILES 9216

// Size of the color palette (256 colors, 3 components for each color)
#define PALETTE_SIZE (256 * 3)

// Current version of this software
#define VERSION "0.1"

// Animation types
const char* AnimationTypes [4] = {"none", "oscillation", "forward", "backward"};

// Blood palette
const uint8 BloodPalette [PALETTE_SIZE] =
{
  0,   0,   0,   8,   8,   8,  16,  16,  16,  24,  24,  24,
 32,  32,  32,  40,  40,  40,  48,  48,  48,  56,  56,  56,
 64,  64,  64,  72,  72,  72,  80,  80,  80,  88,  88,  88,
 96,  96,  96, 104, 104, 104, 112, 112, 112, 120, 120, 120,
128, 128, 128, 136, 136, 136, 144, 144, 144, 152, 152, 152,
160, 160, 160, 168, 168, 168, 176, 176, 176, 188, 188, 188,
196, 196, 196, 204, 204, 204, 212, 212, 212, 220, 220, 220,
228, 228, 228, 236, 236, 236, 244, 244, 244, 252, 252, 252,
 24,  20,  20,  36,  28,  28,  48,  40,  40,  60,  52,  52,
 72,  60,  60,  84,  72,  72,  96,  84,  84, 112,  96,  96,
124, 104, 104, 136, 116, 116, 148, 128, 128, 160, 136, 136,
172, 148, 148, 184, 160, 160, 200, 172, 172, 252, 220, 220,
  0,  12,  36,   0,  16,  48,   4,  24,  56,   4,  32,  68,
 12,  40,  80,  20,  52,  92,  28,  60, 104,  36,  72, 116,
 48,  84, 128,  60,  96, 140,  76, 108, 152,  88, 124, 164,
104, 136, 176, 120, 152, 188, 140, 168, 200, 180, 208, 240,
 20,  20,  44,  24,  28,  56,  32,  36,  72,  40,  48,  84,
 44,  60,  96,  52,  72, 112,  56,  84, 124,  64, 100, 140,
 72, 116, 152,  76, 132, 168,  80, 144, 180,  88, 156, 192,
 92, 172, 208, 100, 184, 220, 104, 200, 232, 112, 220, 252,
 12,  20,  56,  16,  24,  64,  20,  32,  76,  28,  40,  84,
 36,  44,  92,  44,  52, 104,  52,  64, 112,  60,  72, 124,
 72,  80, 132,  80,  92, 144,  92, 104, 152, 104, 112, 164,
116, 128, 172, 132, 140, 184, 144, 152, 196, 184, 192, 240,
 16,   8,   8,  24,  12,  12,  32,  16,  16,  40,  24,  20,
 48,  28,  24,  56,  32,  32,  64,  36,  36,  76,  44,  40,
 84,  48,  44,  92,  52,  48, 100,  60,  52, 108,  64,  56,
116,  68,  60, 124,  76,  64, 132,  80,  68, 140,  88,  72,
148,  96,  80, 156, 108,  88, 168, 116,  96, 176, 128, 104,
184, 136, 116, 192, 148, 124, 200, 160, 132, 212, 172, 144,
156,   0,   0, 180,  40,  12, 204,  88,  32, 212, 112,  40,
224, 132,  48, 232, 152,  56, 240, 172,  68, 252, 196,  80,
  8,  20,  48,   8,  24,  60,   8,  28,  72,  12,  32,  84,
 12,  32,  96,  12,  36, 108,  12,  36, 120,  12,  40, 132,
  8,  40, 144,   8,  40, 156,   8,  40, 168,   4,  36, 180,
  4,  36, 192,   0,  32, 208,   0,  32, 220,   0,  36, 252,
  0,   0,  48,   0,   0,  72,   0,   0,  96,   0,   0, 124,
  0,   0, 148,   0,   0, 172,   0,   0, 192,   0,  12, 204,
  0,   0, 236,   0,  80, 252,   0, 112, 252,   0, 152, 252,
  0, 180, 252,   0, 216, 252,   0, 252, 252, 104, 252, 252,
 20,  24,  12,  28,  32,  16,  36,  44,  24,  44,  52,  32,
 52,  64,  44,  60,  76,  52,  72,  84,  60,  80,  96,  72,
 88, 104,  84, 100, 116,  96, 112, 128, 104, 120, 136, 120,
136, 148, 132, 148, 156, 144, 160, 168, 160, 208, 212, 208,
  4,  24,  80,   4,  36, 108,   4,  56, 140,   4,  76, 168,
  4,  96, 200,   4, 124, 216,   0, 140, 232,   0, 144, 252,
  0,  28,   0,   0,  40,   0,   4,  56,   4,  16,  72,  16,
 28,  88,  28,  40, 104,  40,  60, 120,  60,  80, 136,  80,
  0,  20,  36,   0,  28,  44,   4,  36,  56,   4,  44,  68,
  8,  52,  80,  16,  60,  88,  24,  68, 100,  32,  80, 112,
 40,  88, 120,  52, 100, 132,  60, 108, 144,  72, 120, 156,
 88, 132, 164, 100, 144, 176, 116, 156, 188, 132, 172, 200,
  4,  76, 180,  16,  84, 192,  32,  92, 208,  48, 104, 224,
 56, 116, 228,  64, 132, 232,  72, 144, 236,  80, 160, 240,
 92, 176, 240, 100, 184, 240, 116, 200, 244, 124, 212, 244,
140, 216, 248, 148, 228, 248, 164, 232, 248, 172, 240, 252,
 28,  28, 140,  40,  44, 148,  56,  60, 160,  72,  80, 172,
 92, 100, 184, 108, 120, 196, 132, 144, 208, 156, 168, 220,
  8,   8,  20,  12,  12,  32,  20,  20,  48,  24,  28,  60,
 28,  36,  76,  36,  44,  88,  40,  56, 104,  44,  64, 116,
 48,  76, 132,  52,  80, 136,  56,  88, 140,  60,  92, 148,
 64, 100, 152,  72, 108, 156,  76, 112, 160,  80, 120, 168,
 88, 128, 172,  92, 136, 176, 100, 140, 184, 104, 148, 188,
112, 156, 192, 120, 164, 200, 160, 200, 228, 160,   0, 188
};


/* ------------------------ */
/* --- Global variables --- */
/* ------------------------ */

// ART file
FILE* ArtFile = NULL;

// List of tiles in the ART file
uint32 NbTiles = 0;
uint32 TilesStartNum;             // Number of the first tile
Tile_t TilesList [MAX_NB_TILES];

// Color palette (in TGA format: set of {Blue, Green, Red})
uint8 Palette [PALETTE_SIZE];

// Name of the ART file
const char* ArtFileName = NULL;


/* ----------------- */
/* --- Functions --- */
/* ----------------- */

/* ------ Prototypes ------ */

// Dump animation data into "animdata.ini"
static bool DumpAnimationData (void);

// Extract pictures from the ART file
static bool ExtractPictures (void);

// Get a uint16 from a little-endian ordered buffer
static uint16 GetLittleEndianUInt16 (const uint8* Buffer);

// Get a uint32 from a little-endian ordered buffer
static uint32 GetLittleEndianUInt32 (const uint8* Buffer);

// Create the pictures list from the ART header
static bool GetPicturesList (void);

// Load the color palette from the PALETTE.DAT file
static bool LoadPalette (void);

// Set a uint16 into a little-endian ordered buffer
static void SetLittleEndianUInt16 (uint16 Integer, uint8* Buffer);

// Extract the picture at TilesList[TileInd] and save it as PictureName
static bool SpawnTGA (uint32 TileInd, const char* PictureName);


/* ------ Implementations ------ */

/*
====================
DumpAnimationData

Dump animation data into "animdata.ini"
====================
*/
static bool DumpAnimationData (void)
{
   // Variables
   FILE* AnimDataFile;
   uint32 Ind;

   // Create the INI file
   AnimDataFile = fopen ("animdata.ini", "wt");
   if (AnimDataFile == NULL)
   {
      printf ("Error: can't create file \"animdata.ini\"\n");
      return false;
   }

   printf ("Creating \"animdata.ini\"...");
   fflush (stdout);

   // Print some infos at the beginning of the INI file
   fprintf (AnimDataFile,
            "; This file contains animation data from \"%s\"\n"
            "; Extracted by Art2Tga version " VERSION "\n"
            "\n",
            ArtFileName
           );

   // For each tile...
   for (Ind = 0; Ind < NbTiles; Ind++)
      // if it has animation data...
      if (TilesList[Ind].AnimData != 0)
      {
         // if the tile has animation data, print them first
         // Note: "AnimationType" should be the only parameter to check, but Blood seems to
         //       put informations in the other animation flags even when the image
         //       is not declared as an animation.
         if (((TilesList[Ind].AnimData >>  0) & 0x3F) != 0 ||
             ((TilesList[Ind].AnimData >>  6) & 0x03) != 0 ||
             ((TilesList[Ind].AnimData >> 24) & 0x0F) != 0
            )
         {
            fprintf (AnimDataFile,
                     "[tile%04u.tga -> tile%04u.tga]\n",
                     Ind + TilesStartNum, Ind + TilesStartNum + (TilesList[Ind].AnimData & 0x3F)
                    );
            fprintf (AnimDataFile,
                     "   AnimationType=%s\n",
                     AnimationTypes[(TilesList[Ind].AnimData >> 6) & 0x03]
                    );
            fprintf (AnimDataFile,
                     "   AnimationSpeed=%u\n",
                     (TilesList[Ind].AnimData >> 24) & 0x0F
                    );

            fprintf (AnimDataFile, "\n");
         }

         fprintf (AnimDataFile, "[tile%04u.tga]\n", Ind + TilesStartNum);

         fprintf (AnimDataFile,
                  "   XCenterOffset=%d\n",
                  (int8)((TilesList[Ind].AnimData >>  8) & 0xFF)
                 );
         fprintf (AnimDataFile,
                  "   YCenterOffset=%d\n",
                  (int8)((TilesList[Ind].AnimData >> 16) & 0xFF)
                 );
         fprintf (AnimDataFile,
                  "   OtherFlags=%u\n",
                  TilesList[Ind].AnimData >> 28  // those flags is supposed to be useless in the ART format, but Blood seems to use them
                 );

         fprintf (AnimDataFile, "\n");
      }

   fclose (AnimDataFile);
   printf (" done\n\n");
   return true;
}


/*
====================
ExtractPictures

Extract pictures from the ART file
====================
*/
static bool ExtractPictures (void)
{
   // Variables
   uint32 Ind;
   char ImageFileName [13];

   // A little counter...
   printf ("Extracting pictures:    0");
   fflush (stdout);

   for (Ind = 0; Ind < NbTiles; Ind++)
   {
      // Updating counter
      printf ("\b\b\b\b%4u", Ind);
      fflush (stdout);

      sprintf (ImageFileName, "tile%04u.tga", Ind + TilesStartNum);
      SpawnTGA (Ind, ImageFileName);
   }

   printf ("\b\b\b\bdone\n\n");
   return true;
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
GetLittleEndianUInt32

Get a uint32 from a little-endian ordered buffer
====================
*/
static uint32 GetLittleEndianUInt32 (const uint8* Buffer)
{
   return Buffer[0] | (Buffer[1] << 8) | (Buffer[2] << 16) | (Buffer[3] << 24);
}


/*
====================
GetPicturesList

Create the pictures list from the ART header
====================
*/
static bool GetPicturesList (void)
{
   // Variables
   uint8 Buffer [MAX_NB_TILES * 4];
   uint32 Version, TilesEndNum;
   uint32 Ind;
   size_t CrtOffset;

   // Read the first part of the header
   if (fread (Buffer, 1, 16, ArtFile) != 16)
   {
      printf ("Error: invalid ART file: not enough header data\n");
      return false;
   }
   Version       = GetLittleEndianUInt32 (&Buffer[ 0]);
   NbTiles       = GetLittleEndianUInt32 (&Buffer[ 4]); // useless; overwritten below
   TilesStartNum = GetLittleEndianUInt32 (&Buffer[ 8]);
   TilesEndNum   = GetLittleEndianUInt32 (&Buffer[12]);

   // Compute the real number of tiles contained in the file
   NbTiles = TilesEndNum - TilesStartNum + 1;

   // Check the version number
   if (Version != 1)
   {
      printf ("Error: invalid ART file: invalid version number (%u)\n", Version);
      return false;
   }

   printf ("%u tiles declared in the ART header\n", NbTiles);

   // Extract sizes
   fread (Buffer, 1, NbTiles * 2, ArtFile);
   for (Ind = 0; Ind < NbTiles; Ind++)
      TilesList[Ind].XSize = GetLittleEndianUInt16 (&Buffer[Ind * 2]);
   fread (Buffer, 1, NbTiles * 2, ArtFile);
   for (Ind = 0; Ind < NbTiles; Ind++)
      TilesList[Ind].YSize = GetLittleEndianUInt16 (&Buffer[Ind * 2]);

   // Extract animation data
   fread (Buffer, 1, NbTiles * 4, ArtFile);
   for (Ind = 0; Ind < NbTiles; Ind++)
      TilesList[Ind].AnimData = GetLittleEndianUInt32 (&Buffer[Ind * 4]);

   // Compute offsets
   CrtOffset = 16 + NbTiles * (2 + 2 + 4);
   for (Ind = 0; Ind < NbTiles; Ind++)
   {
      TilesList[Ind].Offset = CrtOffset;
      CrtOffset += TilesList[Ind].XSize * TilesList[Ind].YSize;
   }

   return true;
}


/*
====================
LoadPalette

Load the color palette from the PALETTE.DAT file
====================
*/
static bool LoadPalette (void)
{
   // Variables
   FILE* PaletteFile;
   uint32 Ind;
   uint8 Color;

   // Open the file
   PaletteFile = fopen ("palette.dat", "rb");
   if (PaletteFile == NULL)
   {
      printf ("Warning: can't open \"palette.dat\"\n");
      return false;
   }

   // Read the palette
   if (fread (Palette, 1, PALETTE_SIZE, PaletteFile) != PALETTE_SIZE)
   {
      printf ("Warning: can't read the whole palette from \"palette.dat\" file\n");
      fclose (PaletteFile);
      return false;
   }

   // Convert it to TGA palette format
   for (Ind = 0; Ind < PALETTE_SIZE; Ind += 3)
   {
      Color = Palette[Ind];
      Palette[Ind] = (uint8)(Palette[Ind + 2] << 2);
      Palette[Ind + 1] <<= 2;
      Palette[Ind + 2] = (uint8)(Color << 2);
   }

   printf ("Palette successfully loaded\n");
   fclose (PaletteFile);
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
   // Header
   printf ("\n"
           "Art2Tga version " VERSION " by Mathieu Olivier\n"
           "======================================\n\n"
          );

   // Check arguments
   if (ArgC != 2)
   {
      printf ("Syntax: art2tga <ART file name>\n"
              "   Extract pictures from an ART file under \"tile????.tga\".\n"
              "   Ex: Art2Tga tiles000.art\n"
             );
      return EXIT_FAILURE;
   }

   ArtFileName = ArgV[1];

   // Load the color palette
   if (! LoadPalette ())
   {
      printf ("Using Monolith's Blood(TM) hardcoded palette\n");
      memcpy (Palette, BloodPalette, sizeof (Palette));
   }
   printf ("\n");

   // Open the ART file
   ArtFile = fopen (ArgV[1], "rb");
   if (ArtFile == NULL)
   {
      printf ("Error: can't open file \"%s\"\n", ArgV[1]);
      return EXIT_FAILURE;
   }

   // Extract all the pictures and create the INI file
   if (! GetPicturesList   () ||  // Read the ART header
       ! ExtractPictures   () ||  // Extract pictures from the ART file
       ! DumpAnimationData ()  )  // Dump animation data into "animdata.ini"
   {
      fclose (ArtFile);
      return EXIT_FAILURE;
   }

   fclose (ArtFile);
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
SpawnTGA

Extract the picture number "PictureInd" and save it as PictureName
====================
*/
static bool SpawnTGA (uint32 TileInd, const char* PictureName)
{
   // Variables
   FILE* ImageFile;
   int32 XInd, YInd;
   uint8 TgaHeader [] =
   {
      0x00,                          // Number of Characters in Identification Field (0)
      0x01,                          // Color Map Type (true)
      0x01,                          // Image Type Code (1 -> uncompressed color mapped)
      0x00, 0x00, 0x00, 0x01, 0x18,  // Color Map Specification (from index 0; 256 colors; 24 bits each)
      0x00, 0x00, 0x00, 0x00,        // Origin of Image (0, 0)
      0x00, 0x00, 0x00, 0x00,        // Size of Image (TO BE FILLED. Bytes 12-13 and 14-15. little-endian)
      0x08,                          // Pixel size (8 bits)
      0x00                           // Flags (image described from bottom left; no alpha bits)
   };
   uint8* ImageBuffer;
   const uint32 PictureSize = TilesList[TileInd].XSize * TilesList[TileInd].YSize;

   // If the picture is empty, we skip it
   if (PictureSize == 0)
      return true;

   // Load the picture in a buffer
   fseek (ArtFile, TilesList[TileInd].Offset, SEEK_SET);
   ImageBuffer = malloc (PictureSize);
   if (ImageBuffer == NULL)
   {
      printf ("Error: can't allocate enough memory to load \"%s\"\n", PictureName);
      return false;
   }
   if (fread (ImageBuffer, 1, PictureSize, ArtFile) != PictureSize)
   {
      printf ("Error: can't read enough data in the ART file to load \"%s\"\n", PictureName);
      free (ImageBuffer);
      return false;
   }

   // Create the file
   ImageFile = fopen (PictureName, "wb");
   if (ImageFile == NULL)
   {
      printf ("Error: can't create file \"%s\"\n", PictureName);
      free (ImageBuffer);
      return false;
   }

   // Write the TGA header (including the palette)
   SetLittleEndianUInt16 (TilesList[TileInd].XSize, &TgaHeader[12]);
   SetLittleEndianUInt16 (TilesList[TileInd].YSize, &TgaHeader[14]);
   fwrite (TgaHeader, 1, sizeof (TgaHeader), ImageFile);
   fwrite (Palette, 1, PALETTE_SIZE, ImageFile);

   // Write the picture
   for (YInd = TilesList[TileInd].YSize - 1; YInd >= 0; YInd--)  // save the lines from bottom
      for (XInd = 0; XInd < TilesList[TileInd].XSize; XInd++)
         // ART file store pictures by columns, not by lines
         fwrite (&ImageBuffer[YInd + XInd * TilesList[TileInd].YSize], 1, 1, ImageFile);

   free (ImageBuffer);
   fclose (ImageFile);
   return true;
}
