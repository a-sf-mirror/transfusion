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
#define MAXTILES 9216 // Redneck Rampage uses the most textures. I should make this dynamic
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

/* Constants */
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
int ang, numsectors, numwalls, numsprites, tilesizx[MAXTILES], tilesizy[MAXTILES];

sector_t	*sector; // Points to the dynamically allocated sector array
wall_t		*wall;   // Points to the dynamically allocated wall array
sprite_t	*sprite; // Points to the dynamically allocated sprite array
short		*M_Wall;

//TODO: input function descriptions
// Prototypes

// blood.c
void Blood_To_qBlood (unsigned short i, FILE *NewMap);

// ceiling.c
void WriteCeiling(FILE *NewMap, long SectorNumber, long Plus);

// floor.c
short G_2va(long x1, long y1, long x2, long y2, long *x, long *y);
long GetZ(double p1x, double p1y, double p3x, double p3y, double Z, double ang);
short TestAngles(long SectorNumber);
void WriteFloor  (FILE *NewMap, long SectorNumber, long Plus);
long FindWall(long SectorNumber);   // Validates the number of walls in a sector

// items.c
void I_Sprites(FILE *NewMap);
void W_MusicanDSFX(long i, char *Name, FILE *NewMap);
void W_OtherItems(long i, char *Name, FILE *NewMap);
void E_Item(long i, char *Name, FILE *NewMap, short SpawnFlag);
void WriteItems(FILE *NewMap);
void W_AddLight(FILE* f, short i, short brightness);
void GetSizes(char *FName, long pos);
void I_Sizes(char *FName);

// map2map.c
void ReadMap(char *FName);  // Reads in sectors, walls, sprites from a build map

// recalc.c
void CalcAll();

// s_sector.c
long FindWalls(long SectorNumber);
short Draw_Sector_II(FILE *NewMap, long i);
void DrawBrush_II(FILE *NewMap, long WallNumber, long SectorFloor, long SectorCeiling);
void W_Sector_II(FILE *NewMap, long SectorNumber, long Up, long Down);

/* w_sector.c */

// Finds the extreme points of a sector, and writes the floor and ceiling as squares.
void DivAndWrite(FILE *NewMap, long i, long Up, long Down);
void D_Sector(FILE *NewMap, long i);

// w_win97.c
void W_Wall(TPoint point1, TPoint point2, FILE *NewMap, TWall Wall);
void WriteLine(long x1, long y1, long z1, long x2, long y2, long z2, long x3, long y3, long z3, 
               char *Texture, TWall Wall, FILE *NewMap);

void W_FlatSprite(long x, long y, long z, long angle, long width, long height, 
                  TWall Wall, FILE *NewMap);

/* wall.c */
void WriteWall(TPoint point1, TPoint point2, FILE *NewMap, long i);

// walls.c
void DrawSectorWalls(FILE *NewMap, long i);
void WriteWalls(FILE *NewMap);
void W_MWalls(FILE *NewMap); // Masked walls & windows 

#endif
