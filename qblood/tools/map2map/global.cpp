#include "global.h"

/*
long posx, posy, posz, Divider = 16, MaxV = 1024;
int         ang, numsectors, numwalls, numsprites;
sector_t  sector[1024];
wall_t    wall[8192];
sprite_t  sprite[4096];
short       M_Wall[8192];
*/

long posx, posy, posz, UzS = 2000, UzW = 9000, Divider = 11, MaxV = 1024;
int ang, numsectors, numwalls, numsprites, tilesizx[100000], tilesizy[100000];;

sector_t  sector[4025];
wall_t    wall[18192];
sprite_t  sprite[4096];
short       M_Wall[18192];

/*
long DNAngle2Deg(long angle)
{
 return 0;
}
*/