//
// groupspr.c
//
// Group all frames in a Quake SPR file so that they
// will be automatically animated by the engine
//
// Development version (2002-03-23)
//

/* Copyright (C) 2002  Mathieu Olivier  <elric@planetblood.com>
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

typedef struct
{
    char  name [4];
    int   version;
    int   type;
    float radius;
    int maxwidth;
    int maxheight;
    int nbframes;
    float beamlength;
    int synchtype;
} spr_header_t;


typedef struct
{
    int offsetx;
    int offsety;
    int width;
    int height;
} frame_header_t;


int main (int argc, char* argv [])
{
    // Variables
    FILE *InFile, *OutFile;
    unsigned char Buffer [4096];
    unsigned int NbFrames;
    spr_header_t* SprHeader;
    frame_header_t* FrameHeader;
    unsigned int Ind, Size;
    int Integer;
    float AnimationTime;

    // Syntax checking
    if (argc != 4)
    {
        printf ("Syntax: groupspr <SPR file> <new file> <total animation time (sec)>\n");
        return EXIT_FAILURE;
    }

    // Open the files
    InFile = fopen (argv[1], "rb");
    OutFile = fopen (argv[2], "wb");
    if (InFile == NULL || OutFile == NULL)
    {
        printf ("Error while openging files\n");
        return EXIT_FAILURE;
    }

    // Copy the header
    if (fread (Buffer, 1, sizeof (spr_header_t), InFile) != sizeof (spr_header_t))
    {
        printf ("Error: file too small (header)\n");
        return EXIT_FAILURE;
    }
    SprHeader = (spr_header_t*)Buffer;
    NbFrames = SprHeader->nbframes;
    SprHeader->nbframes = 1;
    fwrite (Buffer, 1, sizeof (spr_header_t), OutFile);

    // Write the group header (SPR_GROUP + nb of frames + time intervals)
    Integer = 1;
    fwrite (&Integer, 1, 4, OutFile);
    fwrite (&NbFrames, 1, 4, OutFile);

    AnimationTime = (float)atof (argv[3]);
    if (AnimationTime < 0.01f)
        AnimationTime = 1.0f;
    for (Ind = 0; Ind < NbFrames; Ind++)
    {
        float TimeInterval = (Ind + 1) * AnimationTime / (float)NbFrames;
        fwrite (&TimeInterval, 1, 4, OutFile);
    }

    // Group all the remaining frames
    printf ("Processing %i frames...\n", NbFrames);
    for (Ind = 0; Ind < NbFrames; Ind++)
    {
        // Read the single frame header
        fread (Buffer, 1, 4, InFile);  // skip the group type
        if (fread (Buffer, 1, sizeof (frame_header_t), InFile) != sizeof (frame_header_t))
        {
            printf ("Error: file too small (frame header %i)\n", Ind);
            return EXIT_FAILURE;
        }
        fwrite (Buffer, 1, sizeof (frame_header_t), OutFile);
        FrameHeader = (frame_header_t*)Buffer;
        Size = FrameHeader->width * FrameHeader->height;
        assert (Size <= sizeof (Buffer));

        // Extract the picture itself
        if (fread (Buffer, 1, Size, InFile) != Size)
        {
            printf ("Error: file too small (frame picture %i)\n", Ind);
            return EXIT_FAILURE;
        }
        fwrite (Buffer, 1, Size, OutFile);
    }

    printf ("Conversion successfully completed\n");

    fclose (InFile);
    fclose (OutFile);
    return EXIT_SUCCESS;
}
