/*
 * Copyright (C) 2002-2005  Mathieu Olivier
 *
 * Group/ungroup all frames of a Quake sprite so that it will be automatically
 * animated by the engine
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


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


// ====================================================================
//                             CONSTANTS
// ====================================================================

#define VERSION "1.0"

// Default time interval for a frame (in sec)
#define DEFAULT_TIME_INTERVAL 0.1f

// Sprite versions
#define SPRITE_VERSION		1	// palettized
#define SPRITE32_VERSION	32	// 32-bit


// ====================================================================
//                             TYPES
// ====================================================================

typedef unsigned char byte;
typedef enum { SPR_SINGLE, SPR_GROUP } frame_group_t;
typedef enum { false, true } boolean;

typedef struct
{
	char	name [4];
	int		version;
	int		type;
	float	radius;
	int		maxwidth;
	int		maxheight;
	int		nbframes;
	float	beamlength;
	int		synchtype;
} spr_header_t;


typedef struct
{
	int offsetx;
	int offsety;
	int width;
	int height;
} frame_header_t;


// ====================================================================
//                             VARIABLES
// ====================================================================

// Work buffer. Used when extracting file contents
unsigned char Buffer [16384];

boolean VerboseMode = false;

unsigned int BytesPerPixel = 1;


// ====================================================================
//                             FUNCTIONS
// ====================================================================

#ifdef WIN32
# define snprintf _snprintf
#endif


/*
====================
GetLittleEndianUint
====================
*/
unsigned int GetLittleEndianUint (const byte* Ptr)
{
	return (Ptr[0]) | (Ptr[1] << 8) | (Ptr[2] << 16) | (Ptr[3] << 24);
}


/*
====================
PutLittleEndianUint
====================
*/
void PutLittleEndianUint (unsigned int Uint, byte* Ptr)
{
	Ptr[0] = (byte)(Uint      );
	Ptr[1] = (byte)(Uint >>  8);
	Ptr[2] = (byte)(Uint >> 16);
	Ptr[3] = (byte)(Uint >> 24);
}


/*
====================
GetLittleEndianFloat
====================
*/
float GetLittleEndianFloat (const byte* Ptr)
{
	unsigned int Float = GetLittleEndianUint (Ptr);
	return *((float*)(&Float));
}


/*
====================
PutLittleEndianFloat
====================
*/
void PutLittleEndianFloat (float Float, byte* Ptr)
{
	PutLittleEndianUint(*((unsigned int*)(&Float)), Ptr);
}


/*
====================
ExportSprHeader
====================
*/
void ExportSprHeader (const spr_header_t* Header, byte* Ptr)
{
	memcpy (Ptr, Header->name, sizeof(Header->name));	Ptr += 4;
	PutLittleEndianUint (Header->version, Ptr);			Ptr += 4;
	PutLittleEndianUint (Header->type, Ptr);			Ptr += 4;
	PutLittleEndianFloat (Header->radius, Ptr);			Ptr += 4;
	PutLittleEndianUint (Header->maxwidth, Ptr);		Ptr += 4;
	PutLittleEndianUint (Header->maxheight, Ptr);		Ptr += 4;
	PutLittleEndianUint (Header->nbframes, Ptr);		Ptr += 4;
	PutLittleEndianFloat (Header->beamlength, Ptr);		Ptr += 4;
	PutLittleEndianUint (Header->synchtype, Ptr);
}


/*
====================
ImportSprHeader
====================
*/
void ImportSprHeader (const byte* Ptr, spr_header_t* Header)
{
	memcpy (Header->name, Ptr, sizeof(Header->name));	Ptr += 4;
	Header->version = GetLittleEndianUint(Ptr);			Ptr += 4;
	Header->type = GetLittleEndianUint(Ptr);			Ptr += 4;
	Header->radius = GetLittleEndianFloat(Ptr);			Ptr += 4;
	Header->maxwidth = GetLittleEndianUint(Ptr);		Ptr += 4;
	Header->maxheight = GetLittleEndianUint(Ptr);		Ptr += 4;
	Header->nbframes = GetLittleEndianUint(Ptr);		Ptr += 4;
	Header->beamlength = GetLittleEndianFloat(Ptr);		Ptr += 4;
	Header->synchtype = GetLittleEndianUint(Ptr);
}


/*
====================
ExportFrameHeader
====================
*/
void ExportFrameHeader (const frame_header_t* Header, byte* Ptr)
{
	PutLittleEndianUint (Header->offsetx, Ptr);	Ptr += 4;
	PutLittleEndianUint (Header->offsety, Ptr);	Ptr += 4;
	PutLittleEndianUint (Header->width, Ptr);	Ptr += 4;
	PutLittleEndianUint (Header->height, Ptr);
}


/*
====================
ImportFrameHeader
====================
*/
void ImportFrameHeader (const byte* Ptr, frame_header_t* Header)
{
	Header->offsetx = GetLittleEndianUint(Ptr);	Ptr += 4;
	Header->offsety = GetLittleEndianUint(Ptr);	Ptr += 4;
	Header->width = GetLittleEndianUint(Ptr);	Ptr += 4;
	Header->height = GetLittleEndianUint(Ptr);
}


/*
====================
LoadAndSaveFrame
====================
*/
boolean LoadAndSaveFrame (FILE *InFile, FILE *OutFile, unsigned int GroupInd, int FrameInd)
{
	char FrameName [32];
	frame_header_t FrameHeader;
	size_t Size;

	if (FrameInd >= 0)
		snprintf (FrameName, sizeof (FrameName), "%u.%i", GroupInd, FrameInd);
	else
		snprintf (FrameName, sizeof (FrameName), "%u", GroupInd);

	// Extract and save the frame header
	if (fread (Buffer, 1, sizeof (frame_header_t), InFile) != sizeof (frame_header_t))
	{
		printf ("Error: file too small (frame header %s)\n", FrameName);
		return false;
	}
	fwrite (Buffer, 1, sizeof (frame_header_t), OutFile);

	ImportFrameHeader (Buffer, &FrameHeader);
	if (VerboseMode)
	{
		printf ("  -> Properties of frame %s: dimensions = %u x %u, origin = (%i, %i)\n",
				FrameName, FrameHeader.width, FrameHeader.height,
				FrameHeader.offsetx, FrameHeader.offsety);
	}

	if (FrameHeader.width <= 0 || FrameHeader.height <= 0)
	{
		printf ("Error: invalid frame size (frame header %s)\n", FrameName);
		return false;
	}
	Size = FrameHeader.width * FrameHeader.height * BytesPerPixel;

	// Extract and save the picture itself
	while (Size > 0)
	{
		size_t NbBytes = ((Size <= sizeof (Buffer)) ? Size : sizeof (Buffer));
		if (fread (Buffer, 1, NbBytes, InFile) != NbBytes)
		{
			printf ("Error: file too small (frame picture %s)\n", FrameName);
			return false;
		}
		fwrite (Buffer, 1, NbBytes, OutFile);
		Size -= NbBytes;
	}

	return true;
}


/*
====================
UngroupAll
====================
*/
int UngroupAll (FILE *InFile, FILE *OutFile, spr_header_t* SprHeader)
{
	unsigned int NbGroups, NbFrames, Ind;

	NbGroups = SprHeader->nbframes;
	fwrite (Buffer, 1, sizeof (spr_header_t), OutFile);

	// Ungroup all the frames
	NbFrames = 0;
	for (Ind = 0; Ind < NbGroups; Ind++)
	{
		frame_group_t FrameType;

		// Read the single frame header
		fread (Buffer, 1, 4, InFile);
		FrameType = GetLittleEndianUint(Buffer);

		if (FrameType == SPR_SINGLE)
		{
			if (VerboseMode)
				printf ("* Parsing element %i (single frame)\n", Ind);

			fwrite (Buffer, 1, 4, OutFile);
			if (!LoadAndSaveFrame(InFile, OutFile, Ind, -1))
				return EXIT_FAILURE;
			NbFrames++;
		}
		else
		{
			unsigned int NbGroupFrames;
			unsigned int FrameInd;

			if (VerboseMode)
				printf ("* Parsing element %i (frame group)\n", Ind);

			// Get the number of grouped frames and skip the time intervals
			fread (Buffer, 1, 4, InFile);
			NbGroupFrames = GetLittleEndianUint (Buffer);
			if (VerboseMode)
				printf ("  -> Group contains %i frames\n", NbGroupFrames);
			if (VerboseMode)
			{
				float TimeInterval;
				fseek (InFile, (NbGroupFrames - 1) * 4, SEEK_CUR);
				fread (Buffer, 1, 4, InFile);
				TimeInterval = GetLittleEndianFloat (Buffer);
				printf ("  -> Total animation time is: %g sec\n", TimeInterval);
			}
			else
				fseek (InFile, NbGroupFrames * 4, SEEK_CUR);

			for (FrameInd = 0; FrameInd < NbGroupFrames; FrameInd++)
			{
				PutLittleEndianUint (SPR_SINGLE, Buffer);
				fwrite (Buffer, 1, 4, OutFile);

				if (!LoadAndSaveFrame(InFile, OutFile, Ind, FrameInd))
					return EXIT_FAILURE;
			}

			NbFrames += NbGroupFrames;
		}
		if (VerboseMode)
			printf("\n");
	}

	// Update the header with the real number of frames
	fseek (OutFile, 24, SEEK_SET);
	PutLittleEndianUint (NbFrames, Buffer);
	fwrite (Buffer, 1, 4, OutFile);

	return EXIT_SUCCESS;
}


/*
====================
GroupAll
====================
*/
int GroupAll (FILE *InFile, FILE *OutFile, spr_header_t* SprHeader, float AnimationTime)
{
	unsigned int NbFrames, Ind;

	NbFrames = SprHeader->nbframes;
	SprHeader->nbframes = 1;  // we will only have 1 element (1 group)
	ExportSprHeader (SprHeader, Buffer);
	fwrite (Buffer, 1, sizeof (spr_header_t), OutFile);

	// Write the group header (SPR_GROUP + nb of frames + time intervals)
	PutLittleEndianUint(SPR_GROUP, Buffer);
	PutLittleEndianUint(NbFrames, Buffer + 4);
	fwrite (Buffer, 2, 4, OutFile);

	if (AnimationTime < 0.01f)
		AnimationTime = DEFAULT_TIME_INTERVAL * NbFrames;
	for (Ind = 0; Ind < NbFrames; Ind++)
	{
		float TimeInterval = (Ind + 1) * AnimationTime / (float)NbFrames;
		fwrite (&TimeInterval, 1, 4, OutFile);
	}

	// Group all the frames
	for (Ind = 0; Ind < NbFrames; Ind++)
	{
		frame_group_t FrameType;

		// Read the single frame header
		fread (Buffer, 1, 4, InFile);
		FrameType = GetLittleEndianUint(Buffer);

		// Make sure it's a single frame, not a group
		if (FrameType != SPR_SINGLE)
		{
			printf ("Error: sprite already contains grouped frames (element %i)\n", Ind);
			return EXIT_FAILURE;
		}
		if (VerboseMode)
			printf ("* Parsing element %i (single frame)\n", Ind);

		if (!LoadAndSaveFrame(InFile, OutFile, Ind, -1))
			return EXIT_FAILURE;

		if (VerboseMode)
			printf ("\n");
	}

	return EXIT_SUCCESS;
}


/*
====================
PrintHelp
====================
*/
void PrintHelp (void)
{
	printf ("This tool groups (or ungroups) all the frames in a Quake sprite "
			"or a DarkPlaces sprite32.\n"
			"\n"
			"Syntax: groupspr [options] <sprite file> <new file>\n"
			"Available options are:\n"
			"   -h        : this help\n"
			"   -t <time> : set the total animation time in seconds.\n"
			"               By default, each frame is given %g seconds\n"
			"   -u        : ungroup the frames instead of grouping them\n"
			"   -v        : verbose mode\n",
			DEFAULT_TIME_INTERVAL);
}


/*
====================
Main
====================
*/
int main (int argc, char* argv [])
{
	FILE *InFile, *OutFile;
	int Result, ArgInd;
	float TimeInterval = 0.0f;
	boolean Ungroup = false;
	spr_header_t SprHeader;

	printf ("\n"
			"GroupSPR, version " VERSION ", by Mathieu Olivier\n"
			"=========================================\n"
			"\n");

	// Check options
	for (ArgInd = 1; (ArgInd < argc) && (argv[ArgInd][0] == '-'); ArgInd++)
	{
		switch (argv[ArgInd][1])
		{
			// Animation time
			case 't':
				ArgInd++;
				if (ArgInd < argc)
					TimeInterval = (float)atof(argv[ArgInd]);
				break;

			// Ungrouping
			case 'u':
				Ungroup = true;
				break;

			// Verbose mode
			case 'v':
				VerboseMode = true;
				break;

			// Wrong option and help
			default:
				printf ("ERROR: unknown option (%s)\n", argv[ArgInd]);
			case 'h':
				PrintHelp ();
				return EXIT_FAILURE;
		}
	}

	// Check we still have enough arguments for the file names
	if (ArgInd + 1 >= argc)
	{
		PrintHelp();
		return EXIT_FAILURE;
	}

	// Open the files
	InFile = fopen (argv[ArgInd++], "rb");
	OutFile = fopen (argv[ArgInd++], "wb");
	if (InFile == NULL || OutFile == NULL)
	{
		printf ("Error while opening the files\n");
		return EXIT_FAILURE;
	}

	// Copy the header
	if (fread (Buffer, 1, sizeof (spr_header_t), InFile) != sizeof (spr_header_t))
	{
		printf ("Error: file too small (header)\n");
		return EXIT_FAILURE;
	}
	ImportSprHeader (Buffer, &SprHeader);

	// Check magic number and version
	if (memcmp (SprHeader.name, "IDSP", 4) != 0)
	{
		printf ("Error: file is not a Quake sprite\n");
		return EXIT_FAILURE;
	}
	if (SprHeader.version != SPRITE_VERSION && SprHeader.version != SPRITE32_VERSION)
	{
		printf ("Error: wrong sprite version (%d instead of %d or %d)\n",
				SprHeader.version, SPRITE_VERSION, SPRITE32_VERSION);
		return EXIT_FAILURE;
	}
	BytesPerPixel = ((SprHeader.version == SPRITE32_VERSION) ? 4 : 1);

	printf ("* %s a %s (%d elements(s), max size = %u x %u)...\n\n",
		Ungroup ? "Ungrouping" : "Grouping",
			(SprHeader.version == SPRITE32_VERSION) ? "DarkPlaces sprite32" : "Quake sprite",
			SprHeader.nbframes, SprHeader.maxwidth, SprHeader.maxheight);

	if (Ungroup)
		Result = UngroupAll(InFile, OutFile, &SprHeader);
	else
		Result = GroupAll(InFile, OutFile, &SprHeader, TimeInterval);

	if (Result == EXIT_SUCCESS)
		printf ("* Conversion successfully completed\n");

	fclose (InFile);
	fclose (OutFile);
	return Result;
}
