#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#include <stdio.h>  // FILE, fread, fprintf, sprintf, printf, fopen, fclose
#include <string.h> // strcmp, strcpy
#include <math.h>   // sqrt, tan, acos, sin, cos, atan2
#include <stdlib.h> // malloc, free, srand, rand
#include <time.h>   // time

#ifdef _MSC_VER // Microsoft Visual C
#pragma warning (disable:4244) // Possible loss of data
#pragma warning (disable:4514) // The optimizer removed an inline function that is not called
#endif

// Constants
#define SCALE 8 //Divider = 16 , was 11 when I started- TIM
#define MAXTILES 9216 // Redneck Rampage uses the most textures. ARTFILES * 256?
#define THICK 2 // Generic brush thickness, 1 causes bsp issues with quake 1
#define NORMAL 0
#define ALTERED 1
#define ZADJUST 14.5 // Was 18 when I started
#define BLOOD
#define QUAKE1 // This is what qBlood needs 

// TESTME: I should try this on more games.
#ifdef QUAKE1
#define MAPSCALE 2 // quake 1 
#define TEXTUREPREFIX
#else
#define MAPSCALE 1 // 1 for quake 2, 3, HL
#define TEXTUREPREFIX "blood\"" // This should be tweaked for each "to" game. 
#endif

#define ZSCALE (MAPSCALE * -128)


// I should consider putting more games here.
#ifdef BLOOD
#define ARTFILES 17 //There are 18 blood art files (numbered from 0)
#endif

/***** Constants *****/
#define ANGLESCALE 5.69 // 2048/360, but to 2 places past decimal only. 2048=build 360=quake
#define PI 3.1415926535897932384626433832795  // Taken from the windows calculator


/* Macro to swap two values */
#define SWAP(x,y)   ((x)^=(y)^=(x)^=(y))


typedef struct
{
 long x, y, zt, zb;
} TPoint;

typedef struct
{
 int   x_off;
 int   y_off;
 int   rot_angle;
 float x_scale;
 float y_scale;
 int   content_a;
 int   surface_a;
 int   light_v;
 long  texture;
} TWall;

typedef struct
{
 short        wallptr, wallnum;
 long         ceilingz, floorz;
 short        ceilingstat, floorstat;
 short        ceilingpicnum, ceilingheinum;
 signed char  ceilingshade;
 char         ceilingpal, ceilingxpanning, ceilingypanning;
 short        floorpicnum, floorheinum;
 signed char  floorshade;
 char         floorpal, floorxpanning, floorypanning;
 char         visibility, filler;
 short        lotag, hitag, extra;
} sector_t;

typedef struct
{
 long         x, y;
 short        point2, nextwall, nextsector, cstat;
 short        picnum, overpicnum;
 signed char  shade;
 char         pal, xrepeat, yrepeat, xpanning, ypanning;
 short        lotag, hitag, extra;
} wall_t;

typedef struct
{
 long           x, y, z;
 short          cstat, picnum;
 signed char    shade;
 char           pal, clipdist, filler;
 unsigned char  xrepeat, yrepeat;
 signed char    xoffset, yoffset;
 short          sectnum, statnum;
 short          ang, owner, xvel, yvel, zvel;
 short          lotag, hitag, extra;
} sprite_t;

// The starting position
long startx, starty, startz;
unsigned short ang, numsectors, numwalls, numsprites, tilesizx[MAXTILES], tilesizy[MAXTILES],
SectorsRounded;

sector_t	*sector; // Points to the dynamically allocated sector array
wall_t		*wall;   // Points to the dynamically allocated wall array
sprite_t	*sprite; // Points to the dynamically allocated sprite array
char		*M_Wall; // Char to save memory, I will change this to something else soon though


/***** blood.c *****/

// Converts blood type sprites to qBlood type entities
void Blood_To_qBlood (const unsigned short i, FILE *NewMap);

// Gets the new qBlood texture name for animated tiles
char* GetNewTextureName(const unsigned short i);


/***** ceiling.c *****/

// Write a sector's ceiling
void WriteCeiling(FILE *NewMap, const unsigned short SectorNumber, short Plus);


/***** floor.c *****/

// Not sure
short G_2va(long x1, long y1, long x2, long y2, long *x, long *y);

// Tests how complicated a sector is (i.e. "fakey curves")
short TestAngles(const unsigned short  SectorNumber);

// Writes a sectors floor
void WriteFloor  (FILE *NewMap, const unsigned short SectorNumber, const long Plus);

// Validates the number of walls in a sector
short FindWall(const unsigned short SectorNumber);

short FindSector(const unsigned short SectorNumber);

/***** items.c *****/

// Gets texture scaling, then writes the flat sprites
void WriteFlatSprites(FILE *NewMap);

// Writes a duke style sfx (will die soon)
void WriteMusicanDSFX(const unsigned short SpriteNumber, const char *Name, FILE *NewMap);

// Writes a simple item
void WriteSimpleItem(const unsigned short i, const char *Name, FILE *NewMap);

// Writes an item with a special spawn flag
void WriteFlaggedItem(const unsigned short i, const char *Name, FILE *NewMap, short SpawnFlag);

// Goes through all the sprites and tries to find acceptable conversions
void WriteItems(FILE *NewMap);

// Places a light entity in a map
void WriteLight(FILE* newmap, const short i, const short brightness, const char* Lightname);

// Will get the tile sizes from a group or art file
void GetSizes(char *FName, const unsigned int offset);

// This expects a group file (.grp) or a directory of art files specifed by "notgroup"
void I_Sizes(char *FName);


/***** map2map.c *****/

// Reads in sectors, walls, sprites from a build map
void ReadMap(const char *FName);  


/***** recalc.c *****/

// Scales a map, and Recenters it. Also fixes the angles format.
void CalcAll();


/***** s_sector.c *****/

// Manually counts the walls in a sector, assuming no crazy looping
long FindWalls(const unsigned short SectorNumber);

// Alternate ???
short AltDrawSector(FILE *NewMap, const unsigned short i);

// Draws counting from a starting wall until the wall comes full circle
void DrawBrush(FILE *NewMap, const unsigned short WallNumber, const long SectorFloor, const long SectorCeiling);

// Alternate ???
void WriteSector(FILE *NewMap, const unsigned short SectorNumber, const short Up, const short Down);


/***** w_sector.c *****/

// Finds the extreme points of a sector, and writes the floor and ceiling as rectangles.
void DivAndWrite(FILE *NewMap, const unsigned short i, const short Up, const short Down);

// The main sector function. Essentially writes all the sectors
void DrawSector(FILE *NewMap, const unsigned short i);


/***** w_win97.c *****/

// Primary wall writing function
void WriteWall(const TPoint point1, const TPoint point2, FILE *f, const TWall wall);

// Writeline circumvents having to use fprintf and it's formating in the text repetatively
void WriteLine(long x1, long y1, long z1, long x2, long y2, long z2, long x3, long y3, long z3, 
               char *Texture, TWall Wall, FILE *NewMap);

// Writes a flat sprite
void WriteFlatSprite(const unsigned short SpriteNumber, const long width, const long height, 
                     TWall wall, FILE *newmap);


/***** wall.c *****/

// Writes a two sided wall (connects two sectors)
void WriteTwoSidedWall(TPoint point1, TPoint point2, FILE *NewMap, const unsigned short i);


/***** wall2.c *****/

// Writes a wall like in b2q
void AlternateWriteWall(FILE *f, const unsigned short WallNumber, const unsigned short SectorNumber, const short Down);


/***** walls.c *****/
void DrawSectorWalls(FILE *NewMap, const unsigned short i, const short Down, const char SectorType);
void WriteTwoSidedWalls(FILE *NewMap);

// Masked walls & windows
void WriteMaskedWalls(FILE *NewMap); 

#endif
