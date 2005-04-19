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
#define BLOOD
#define QUAKE1 // This is what qBlood needs 

// TESTME: I should try this on more games.
#ifdef QUAKE1
#define MAPSCALE 2 // quake 1 
#else
#define MAPSCALE 1 // 1 for quake 2, 3, HL
#endif

// I should consider putting more games here.
#ifdef BLOOD
#define ARTFILES 17 //There are 18 blood art files (numbered from 0)
#endif

/***** Constants *****/
#define ANGLESCALE 5.69 // 2048/360, but to 2 places past decimal only. 2048=build 360=quake
#define PI 3.1415926535897932384626433832795  // Taken from the windows calculator

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
void WriteCeiling(FILE *NewMap, const long SectorNumber, const long Plus);


/***** floor.c *****/

// Not sure
short G_2va(long x1, long y1, long x2, long y2, long *x, long *y);

// ??? Gets a sectors slope Z ???
long GetZ(double p1x, double p1y, double p3x, double p3y, double Z, double ang);

// Tests how complicated a sector is (i.e. "fakey curves")
short TestAngles(const long SectorNumber);

// Writes a sectors floor
void WriteFloor  (FILE *NewMap, const long SectorNumber, long Plus);

// Validates the number of walls in a sector
long FindWall(long SectorNumber);


/***** items.c *****/

// Gets texture scaling, then writes the flat sprites
void WriteFlatSprites(FILE *NewMap);

// Writes a duke style sfx (will die soon)
void W_MusicanDSFX(const unsigned short i, char *Name, FILE *NewMap);

// Writes a simple item
void WriteSimpleItem(const unsigned short i, char *Name, FILE *NewMap);

// Writes an item with a special spawn flag
void WriteFlaggedItem(const unsigned short i, char *Name, FILE *NewMap, short SpawnFlag);

// Goes through all the sprites and tries to find acceptable conversions
void WriteItems(FILE *NewMap);

// Places a light entity in a map
void AddLight(FILE* f, const short i, const short brightness);

// Will get the tile sizes from a group or art file
void GetSizes(char *FName, const long pos);

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

// Alternate
short Draw_Sector_II(FILE *NewMap, const unsigned short i);

// Alternate
void DrawBrush_II(FILE *NewMap, const unsigned short WallNumber, long SectorFloor, long SectorCeiling);

// Alternate
void W_Sector_II(FILE *NewMap, const unsigned short SectorNumber, long Up, long Down);


/***** w_sector.c *****/

// Finds the extreme points of a sector, and writes the floor and ceiling as squares.
void DivAndWrite(FILE *NewMap, const unsigned short i, long Up, long Down);

// The main sector function. Essentially writes all the sectors
void DrawSector(FILE *NewMap, const unsigned short i);


/***** w_win97.c *****/

// Alternate
void W_Wall(TPoint point1, TPoint point2, FILE *NewMap, TWall Wall);

// Writeline circumvents having to use fprintf and it's formating in the text repetatively
void WriteLine(long x1, long y1, long z1, long x2, long y2, long z2, long x3, long y3, long z3, 
               char *Texture, TWall Wall, FILE *NewMap);

// Writes a flat sprite
void W_FlatSprite(long x, long y, long z, long angle, long width, long height, 
                  TWall Wall, FILE *NewMap);


/***** wall.c *****/

// Writes a wall
void WriteWall(TPoint point1, TPoint point2, FILE *NewMap, const unsigned short i);


/***** walls.c *****/
void DrawSectorWalls(FILE *NewMap, const unsigned short i);
void WriteWalls(FILE *NewMap);

// Masked walls & windows
void WriteMaskedWalls(FILE *NewMap); 

#endif
