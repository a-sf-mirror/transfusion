#include "global.h"

short TestAngles(long SecN);
void  WriteFloor  (FILE *f, long SecN, long Plus);
void  WriteCeiling(FILE *f, long SecN, long Plus);
void  W_Floor2(FILE *f, long i, long Plus);
void  W_Ceil2(FILE *f, long i, long Plus);
void  W_Sector_II(FILE *f, long SecN, long Up, long Dn);
void  DrawSectorWalls(FILE *f, long i);
long FindWalls(long SecN);

// What does this function do?
void DivAndWrite(FILE *f, long i, long Up, long Dn)
{
 long maxX = -5000000, maxY = -5000000, minX =  5000000, minY =  5000000, wallpointer, j, TimeOut = 1000;

 DrawSectorWalls(f, i);
 
 // Why 2000? 
 // All this will have to be redesigned when sector/wall/sprite memory allocation goes dynamic
 sector[2000] = sector[i];
 sector[2000].wallnum = 4;
 sector[2000].wallptr = 5001;
 
 wallpointer = sector[i].wallptr;
 j   = sector[i].wallptr;

 do 
 {
  if (wall[j].x > maxX) maxX = wall[j].x;
  if (wall[j].y > maxY) maxY = wall[j].y;
  if (wall[j].x < minX) minX = wall[j].x;
  if (wall[j].y < minY) minY = wall[j].y;
  j = wall[j].point2; TimeOut--;
 } while ( (j != wallpointer) && (TimeOut > 0) );
 
// Why 5001 to 5004
 wall[5001]   = wall[wallpointer];
 wall[5001].x = minX;
 wall[5001].y = minY;
 wall[5001].point2 = 5004;


 wall[5002]   = wall[wallpointer];
 wall[5002].x = maxX;
 wall[5002].y = minY;
 wall[5002].point2 = 5001;
 

 wall[5003]   = wall[wallpointer];
 wall[5003].x = maxX;
 wall[5003].y = maxY;
 wall[5003].point2 = 5002;


 wall[5004]   = wall[wallpointer];
 wall[5004].x = minX;
 wall[5004].y = maxY;
 wall[5004].point2 = 5003;

 // Why 2000?
 WriteFloor  (f, 2000, Dn);
 WriteCeiling(f, 2000, Up);
}


void D_Sector(FILE *f, long i)
{
 int  j;
 long Dn = -15, Up = 1, wallpointer, ST, SB, TimeOut = 1000;
 ST  = sector[i].floorz;
 SB  = sector[i].ceilingz;
 wallpointer = sector[i].wallptr;
 j   = sector[i].wallptr;

 do 
 {
  if (wall[j].nextsector != -1)
  {
   if (sector[wall[j].nextsector].floorz - ST < Dn)
	   Dn = sector[wall[j].nextsector].floorz   - ST;

   if ((sector[wall[j].nextsector].ceilingz - SB > Up)
	   && (sector[wall[j].nextsector].ceilingz != sector[wall[j].nextsector].floorz)) 
	   Up = sector[wall[j].nextsector].ceilingz - SB;

   M_Wall[j] = 1;
   M_Wall[wall[j].nextwall] = 1;
  }
  TimeOut--;
  j = wall[j].point2;
 } while ( (j != wallpointer) && (TimeOut > 0) );
 
 if (!(TimeOut > 0)) 
	 printf("Sector %ld Timed out   Number of walls:%d\n", i, sector[i].wallnum);

 if (!TestAngles(i))  // Why?
 {
	 // Validate the number of walls  
	 if (FindWalls(i) != sector[i].wallnum) 
		W_Sector_II(f, i, Up, Dn);
  
  else
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