#include "global.h"

// This finds the extreme points of a sector, and writes the floor and ceiling as rectangles.
void DivAndWrite(FILE *f, const unsigned short i, const long Up, const long Down)
{
 long maxX = -5000000, maxY = -5000000, minX =  5000000, minY =  5000000, wallpointer, j, TimeOut = 1000;

 DrawSectorWalls(f, i);
 
 // Initialize the temporary sector
 sector[numsectors] = sector[i];        // numsectors is the value for temp sector
 sector[numsectors].wallnum = 4;
 sector[numsectors].wallptr = numwalls; // numwalls is the first value (of 4) for temp walls
 
 wallpointer = j = sector[i].wallptr;

 do // Gather the extreme points
 {
  if (wall[j].x > maxX) 
      maxX = wall[j].x;

  if (wall[j].y > maxY) 
      maxY = wall[j].y;

  if (wall[j].x < minX) 
      minX = wall[j].x;

  if (wall[j].y < minY) 
      minY = wall[j].y;

  j = wall[j].point2; TimeOut--;

 } while ( (j != wallpointer) && (TimeOut > 0) );
 
// Initialize the values for the temp walls
 wall[numwalls]   = wall[wallpointer];
 wall[numwalls].x = minX;
 wall[numwalls].y = minY;
 wall[numwalls].point2 = numwalls+3;


 wall[numwalls+1]   = wall[wallpointer];
 wall[numwalls+1].x = maxX;
 wall[numwalls+1].y = minY;
 wall[numwalls+1].point2 = numwalls;
 

 wall[numwalls+2]   = wall[wallpointer];
 wall[numwalls+2].x = maxX;
 wall[numwalls+2].y = maxY;
 wall[numwalls+2].point2 = numwalls+1;


 wall[numwalls+3]   = wall[wallpointer];
 wall[numwalls+3].x = minX;
 wall[numwalls+3].y = maxY;
 wall[numwalls+3].point2 = numwalls+2;

 // Write the temporary sector
 WriteFloor  (f, numsectors, Down);       // numsectors is the value for temp sector
 WriteCeiling(f, numsectors, Up);
}

// The main sector function. Essentially writes all the sectors
void DrawSector(FILE *f, const unsigned short i)
{
 int  j;
 long Dn = -15, Up = 1, wallpointer, SectorFloorZ, SectorCeilingZ; 
 short TimeOut = 1000;
 SectorFloorZ  = sector[i].floorz;
 SectorCeilingZ  = sector[i].ceilingz;
 wallpointer = sector[i].wallptr;
 j   = sector[i].wallptr;

 do 
 {
  if (wall[j].nextsector != -1) // Attached to another sector
  {
   if (sector[wall[j].nextsector].floorz - SectorFloorZ < Dn)
	   Dn = sector[wall[j].nextsector].floorz   - SectorFloorZ; // For steps?

   if ((sector[wall[j].nextsector].ceilingz - SectorCeilingZ > Up)
	   && (sector[wall[j].nextsector].ceilingz != sector[wall[j].nextsector].floorz)) 
	   Up = sector[wall[j].nextsector].ceilingz - SectorCeilingZ;

   M_Wall[j] = 1;
   M_Wall[wall[j].nextwall] = 1;
  }
  TimeOut--;
  j = wall[j].point2;
 } while ( (j != wallpointer) && (TimeOut > 0) );
 
 if (!(TimeOut > 0)) 
	 printf("Sector %d Timed out in DrawSector(). Number of walls:%d\n", i, sector[i].wallnum);

 if (!TestAngles(i))  // Checks if the sector is drawing fakey "curves"
 {
	 // Validate the number of walls  
	 if (FindWalls(i) != sector[i].wallnum) 
		WriteSector(f, i, Up, Dn); // If walls are doing something freaky, use alternate method
    
     else // It's all good- write the sector regularly
    {
    
        WriteFloor  (f, i, Dn);
        WriteCeiling(f, i, Up);
        DrawSectorWalls(f, i);
    }
 // Otherwise it'll get turned into a rectangle (lame, but it works)
 } else DivAndWrite(f, i, Up, Dn);
 
 
}