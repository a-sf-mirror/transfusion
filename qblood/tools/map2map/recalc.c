#include "global.h"

// Scales a map, and Recenters it. Also fixes the angles format.
void CalcAll()
{
 long MinX = 9999, MinY = 9999, MaxH = -9999, MaxX = -9999, MaxY = -9999;
 short i, Xadjust, Yadjust; 

 printf("Scaling and recentering the coordinates\n");
  
 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz /= ZSCALE; //SCALE; - Build uses units of 128/256/512/1024
  sector[i].floorz   /= ZSCALE; //SCALE;
  /*
  if (sector[i].ceilingz > MaxH) 
	  MaxH = sector[i].ceilingz;
      */
 }

 for (i = 0; i < numwalls; i++)
 {
  if (wall[i].x > MaxX) MaxX = wall[i].x;
  if (wall[i].y > MaxY) MaxY = wall[i].y;
  if (wall[i].x < MinX) MinX = wall[i].x;
  if (wall[i].y < MinY) MinY = wall[i].y;
 }

 /*
 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz = (MaxH - sector[i].ceilingz) / ZADJUST/MAPSCALE; // ZADJUST was 14.5 
  sector[i].floorz   = (MaxH - sector[i].floorz  ) / ZADJUST/MAPSCALE; // while testing E6M8
 }
*/

 for (i = 0; i < numwalls; i++)
 {
  if (MinX < 0) 
  wall[i].x = -4000+(wall[i].x - MinX) / SCALE/MAPSCALE; 
  else
  wall[i].x = -4000+(wall[i].x)        / SCALE/MAPSCALE;

  wall[i].y = -4000+(MaxY - wall[i].y) / SCALE/MAPSCALE;
 }

 for (i = 0; i < numsprites; i++)
 {
  if (MinX < 0) 
  sprite[i].x = -4000+(sprite[i].x - MinX) / SCALE/MAPSCALE; 
  else
  sprite[i].x = -4000+(sprite[i].x)        / SCALE/MAPSCALE;

  sprite[i].y = -4000+(MaxY - sprite[i].y) / SCALE/MAPSCALE;
  sprite[i].z /= ZSCALE; // SCALE;
  //sprite[i].z = (MaxH - sprite[i].z) / ZADJUST/MAPSCALE;

 
  sprite[i].ang /= ANGLESCALE;
 // Angle fixing
 if (sprite[i].ang < 0 || sprite[i].ang > 360)
	 sprite[i].ang = 0;
 }

  if (MinX < 0) 
  startx = -4000+(startx - MinX) / SCALE/MAPSCALE; 
  else
  startx = -4000+(startx)        / SCALE/MAPSCALE;

  starty = -4000+(MaxY - starty) / SCALE/MAPSCALE;
  startz /= ZSCALE; //(MaxH - startz / SCALE) / SCALE/MAPSCALE;

// Now to recenter everything that just got scaled 
  MaxX = MinX = wall[0].x;
  MaxY = MinY = wall[0].y;

  for (i = 0; i < numwalls; i++)
	{
		if (wall[i].x > MaxX) MaxX = wall[i].x;
		if (wall[i].y > MaxY) MaxY = wall[i].y;
		if (wall[i].x < MinX) MinX = wall[i].x;
		if (wall[i].y < MinY) MinY = wall[i].y;
	}
	Xadjust = (MaxX + MinX)/2;
	Yadjust = (MaxY + MinY)/2;
  
	for (i = 0; i < numwalls; i++)
	{
		wall[i].x -= Xadjust;
		wall[i].y -= Yadjust;
	}

	for (i = 0; i < numsprites; i++)
	{
		sprite[i].x -= Xadjust;
		sprite[i].y -= Yadjust;
	}
	
	startx -= Xadjust;
	starty -= Yadjust;
    ang /= ANGLESCALE;
    if (ang < 0 || ang > 360)
	    ang = 0;
}
 
