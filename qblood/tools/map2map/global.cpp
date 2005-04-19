#include "global.h"
//Divider = 16 , was 11 when I started- TIM

long posx, posy, posz, UzS = 2000, UzW = 9000, Divider = 8, MaxV = 1024;
int ang, numsectors, numwalls, numsprites, tilesizx[100000], tilesizy[100000];

sector_t	*sector;
wall_t		*wall;
sprite_t	*sprite;
short		*M_Wall;
