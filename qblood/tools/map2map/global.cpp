#include "global.h"

/*
Divider = 16 , was 11 when I started- TIM
sector_t  sector[1024];
wall_t    wall[8192];
sprite_t  sprite[4096];
short       M_Wall[8192];
*/

long posx, posy, posz, UzS = 2000, UzW = 9000, Divider = 8, MaxV = 1024;
int ang, numsectors, numwalls, numsprites, tilesizx[100000], tilesizy[100000];

sector_t  sector[4025];
wall_t    wall[8192];
sprite_t  sprite[4096];
short       M_Wall[8192];
