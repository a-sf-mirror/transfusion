#include "global.h"

void CalcAll()
{
 long i, MinH = 9999, MinX = 9999, MinY = 9999, MaxH = -9999, MaxX = -9999, MaxY = -9999;
 short Xadjust,Yadjust; 

 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz /= Divider;
  sector[i].floorz   /= Divider;
  if (sector[i].ceilingz > MaxH) MaxH = sector[i].ceilingz;
  if (sector[i].floorz   < MinH) MinH = sector[i].floorz;
 }

 for (i = 0; i < numwalls; i++)
 {
  //wall[i].x = wall[i].x - posx;
  //wall[i].y = wall[i].y - posy;
  if (wall[i].x > MaxX) MaxX = wall[i].x;
  if (wall[i].y > MaxY) MaxY = wall[i].y;
  if (wall[i].x < MinX) MinX = wall[i].x;
  if (wall[i].y < MinY) MinY = wall[i].y;
 }

 for (i = 0; i < numsectors; i++)
 {
  sector[i].ceilingz = (MaxH - sector[i].ceilingz) / 14.5/MAPSCALE; // Divider; // was 18
  sector[i].floorz   = (MaxH - sector[i].floorz  ) / 14.5/MAPSCALE; // Divider;
 }

 for (i = 0; i < numwalls; i++)
 {
  if (MinX < 0) 
  wall[i].x = -4000+(wall[i].x - MinX) / Divider/MAPSCALE; 
  else
  wall[i].x = -4000+(wall[i].x)        / Divider/MAPSCALE;

  wall[i].y = -4000+(MaxY - wall[i].y) / Divider/MAPSCALE;
 }

 for (i = 0; i < numsprites; i++)
 {
  //sprite[i].x = sprite[i].x -posx;
  //sprite[i].y = sprite[i].y -posy;

  if (MinX < 0) 
  sprite[i].x = -4000+(sprite[i].x - MinX) / Divider/MAPSCALE; 
  else
  sprite[i].x = -4000+(sprite[i].x)        / Divider/MAPSCALE;

  sprite[i].y = -4000+(MaxY - sprite[i].y) / Divider/MAPSCALE;
//  sprite[i].z = (MaxH - sprite[i].z  / Divider) / Divider;
  sprite[i].z = sprite[i].z / Divider;
  sprite[i].z = (MaxH - sprite[i].z) / 14.5/MAPSCALE;
 }

  //posx = posx - posx;
  //posy = posx - posy;

  if (MinX < 0) 
  posx = -4000+(posx - MinX) / Divider/MAPSCALE; 
  else
  posx = -4000+(posx)        / Divider/MAPSCALE;

  posy = -4000+(MaxY - posy) / Divider/MAPSCALE;
  posz = (MaxH - posz / Divider) / Divider/MAPSCALE;

/* TESTME: New features = bugs. This should recenter the map ok*/
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
 
