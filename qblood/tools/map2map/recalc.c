#include "global.h"

void CalcAll()
{
 long i, MinX = 9999, MinY = 9999, MaxH = -9999, MaxX = -9999, MaxY = -9999;
 short Xadjust,Yadjust; 

 printf("Scaling and recentering the coordinates\n");
 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz /= SCALE;
  sector[i].floorz   /= SCALE;
  
  if (sector[i].ceilingz > MaxH) 
	  MaxH = sector[i].ceilingz;
 }

 for (i = 0; i < numwalls; i++)
 {
  if (wall[i].x > MaxX) MaxX = wall[i].x;
  if (wall[i].y > MaxY) MaxY = wall[i].y;
  if (wall[i].x < MinX) MinX = wall[i].x;
  if (wall[i].y < MinY) MinY = wall[i].y;
 }

 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz = (MaxH - sector[i].ceilingz) / 14.5/MAPSCALE; // 14.5 was 18
  sector[i].floorz   = (MaxH - sector[i].floorz  ) / 14.5/MAPSCALE; // 
 }

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
  sprite[i].z = sprite[i].z / SCALE;
  sprite[i].z = (MaxH - sprite[i].z) / 14.5/MAPSCALE;
 }

  if (MinX < 0) 
  posx = -4000+(posx - MinX) / SCALE/MAPSCALE; 
  else
  posx = -4000+(posx)        / SCALE/MAPSCALE;

  posy = -4000+(MaxY - posy) / SCALE/MAPSCALE;
  posz = (MaxH - posz / SCALE) / SCALE/MAPSCALE;

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
	
	posx -= Xadjust;
	posy -= Yadjust;

}
 
