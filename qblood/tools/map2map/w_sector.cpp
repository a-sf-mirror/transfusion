#include <stdio.h>
#include "global.h"
#include "s_sector.h"


short TestAngles(long SecN);
void  WriteFloor  (FILE *f, long SecN, long Plus);
void  WriteCeiling(FILE *f, long SecN, long Plus);
void  W_Floor2(FILE *f, long i, long Plus);
void  W_Ceil2(FILE *f, long i, long Plus);
void  W_Sector_II(FILE *f, long SecN, long Up, long Dn);
void  DrawSectorWalls(FILE *f, long i);

long FindWalls(long SecN);



void DivAndWrite(FILE *f, long i, long Up, long Dn)
{
 long maxX = -5000000, maxY = -5000000, minX =  5000000, minY =  5000000, StW, j, TimeOut = 1000;

 DrawSectorWalls(f, i);
 
 sector[2000] = sector[i];
 sector[2000].wallnum = 4;
 sector[2000].wallptr = 5001;
 
 StW = sector[i].wallptr;
 j   = sector[i].wallptr;

 do 
 {
  if (wall[j].x > maxX) maxX = wall[j].x;
  if (wall[j].y > maxY) maxY = wall[j].y;
  if (wall[j].x < minX) minX = wall[j].x;
  if (wall[j].y < minY) minY = wall[j].y;
  j = wall[j].point2; TimeOut--;
 } while ( (j != StW) && (TimeOut > 0) );
 
 wall[5001]   = wall[StW];
 wall[5001].x = minX;
 wall[5001].y = minY;
 wall[5001].point2 = 5004;


 wall[5002]   = wall[StW];
 wall[5002].x = maxX;
 wall[5002].y = minY;
 wall[5002].point2 = 5001;
 

 wall[5003]   = wall[StW];
 wall[5003].x = maxX;
 wall[5003].y = maxY;
 wall[5003].point2 = 5002;


 wall[5004]   = wall[StW];
 wall[5004].x = minX;
 wall[5004].y = maxY;
 wall[5004].point2 = 5003;


 WriteFloor  (f, 2000, Dn);
 WriteCeiling(f, 2000, Up);
}

void D_Sector(FILE *f, long i)
{
 int  j;
 long Dn = -15, Up = 1, StW, ST, SB, TimeOut = 1000;
 ST  = sector[i].floorz;
 SB  = sector[i].ceilingz;
 StW = sector[i].wallptr;
 j   = sector[i].wallptr;

 do 
 {
  if (wall[j].nextsector != -1)
  {
   if (sector[wall[j].nextsector].floorz - ST < Dn)                                                                                  Dn = sector[wall[j].nextsector].floorz   - ST;
   if ((sector[wall[j].nextsector].ceilingz - SB > Up) & (sector[wall[j].nextsector].ceilingz != sector[wall[j].nextsector].floorz)) Up = sector[wall[j].nextsector].ceilingz - SB;
   M_Wall[               j] = 1;
   M_Wall[wall[j].nextwall] = 1;
  }
  TimeOut--;
  j = wall[j].point2;
 } while ( (j != StW) && (TimeOut > 0) );
 if (!(TimeOut > 0)) printf("Sector %ld Timed out\n", i);

 if (!TestAngles(i))
 {
  if (FindWalls(i) != sector[i].wallnum)
  {
   W_Sector_II(f, i, Up, Dn);
   //  W_Floor2(f, i, Dn);
   //  W_Ceil2(f, i, Up);
  } else
  {
   WriteFloor  (f, i, Dn);
   WriteCeiling(f, i, Up);
   DrawSectorWalls(f, i);
  }
 } else
 {
  DivAndWrite(f, i, Up, Dn);
 }
}










