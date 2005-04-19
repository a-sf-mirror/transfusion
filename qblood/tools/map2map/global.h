#ifndef _GLOBAL_H_
#define _GLOBAL_H_

#include <stdio.h>
#include <string.h>
#include <process.h>
#include <math.h>
#include <stdlib.h>

#ifdef _MSC_VER
#pragma warning (disable:4244)
#endif

/* Constants */
#define QUAKE1 /* This is what qBlood needs */

#ifdef QUAKE1
#define MAPSCALE 2 /* quake 1 */
#else
#define MAPSCALE 1 /* 1 for quake 2, 3, HL*/
#endif

//#define XSCALE 16	/* Quake 1 likes 16 as the X scale, it was 8 in dukeconv (q3) */
//#define YSCALE -16	/* Quake 1 likes -16 as the Y scale, it was -8 in dukeconv (q3) */
//#define ZSCALE -256	/* Quake 1 likes -256 as the Z scale, it was -128 in dukeconv (q3) */
/* Constants */
#define ANGLESCALE 5.69 /* 2048/360, but to 2 places past decimal only. 2048=build 360=quake */
#define PI 3.1415926535897932384626433832795  /* Taken from the windows calculator */

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

extern long posx, posy, posz, Divider, MaxV, UzS, UzW;
extern int ang, numsectors, numwalls, numsprites, tilesizx[100000], tilesizy[100000];
extern short       M_Wall[18192];
extern sector_t  sector[4025];
extern wall_t    wall[18192];
extern sprite_t  sprite[4096];

/* Mic Functions
long DNAngle2Deg(long angle);
*/

/* w_win97 */
void W_FlatSprite(long x, long y, long z, long angle, long width, long height, TWall w, FILE *f);

#endif
